# Picko Phase 5 Verification

日期：2026-05-31
工作目录：`/Users/tanzz/workspaces/picko/.worktrees/mvp-core`

## 1. Automated Verification

已运行并通过的本地/平台验证：

1. `swift test`
2. `swift run PickoBenchmarks`
3. iOS simulator build through XcodeBuildMCP.
4. iOS simulator `PickoTests` through XcodeBuildMCP.
5. iOS simulator `PickoUITests` through XcodeBuildMCP, including synthetic in-app metadata benchmark launch, sample pre-delete basket confirmation boundary, sample basket Clear Picko State flow, and denied-library fallback.
6. macOS `PickoMac` app target test through `xcodebuild`, including denied-library launch path compile coverage.
7. `scripts/audit-privacy-logging.sh`
8. `scripts/verify-phase-5-local.sh`
9. `bash -n scripts/verify-phase-5-platform.sh`
10. `scripts/create-phase-5-evidence.sh /private/tmp/picko-phase-5-evidence-smoke.md`
11. `scripts/capture-metadata-baseline.sh --output /tmp/picko-phase-5-evidence-smoke 10`
12. `scripts/verify-phase-5-platform.sh`
13. `scripts/prepare-phase-5-manual-evidence.sh --output /tmp/picko-phase-5-manual-evidence-smoke`
14. `scripts/audit-runtime-privacy-logs.sh /tmp/picko-runtime-log-smoke.log`
15. `scripts/check-phase-5-evidence.sh EVIDENCE_MD`
16. `scripts/check-phase-5-manual-evidence.sh MANUAL_EVIDENCE_DIR`
17. `scripts/report-phase-5-status.sh`
18. `scripts/update-phase-5-ios-benchmark.sh`
19. `scripts/update-phase-5-gate.sh`
20. `scripts/update-phase-5-privacy-review.sh`
21. `scripts/record-runtime-privacy-evidence.sh`
22. `scripts/update-phase-5-manual-verification.sh`
23. `scripts/update-phase-5-host-baseline.sh`
24. `scripts/record-phase-5-completeness-gates.sh` smoke coverage; final gate recording is still pending until external evidence is complete.
25. `scripts/phase-5-external-evidence-checklist.sh`
26. `scripts/update-phase-5-environment.sh`
27. `scripts/check-phase-5-external-runbook.sh docs/Phase-5-External-Evidence-Runbook.md`
28. `scripts/check-phase-5-external-evidence-readiness.sh --evidence docs/phase-5-evidence-2026-05-31.md --manual-dir docs/phase-5-evidence/manual-2026-05-31`
29. `scripts/finalize-phase-5-evidence.sh` smoke coverage; the real finalizer is expected to remain blocked until host Photos baseline and macOS manual evidence are written back.
30. `scripts/create-phase-5-external-evidence-handoff.sh`
31. `scripts/check-phase-5-external-handoff.sh`
32. `scripts/report-mvp-next-development-status.sh` status-gate coverage; current real status remains incomplete while Phase 5 external evidence is missing.
33. `scripts/check-phase-5-verification-doc.sh docs/Phase-5-Verification.md`
34. `scripts/audit-mvp-next-completion.sh` completion-gate coverage; current real audit is expected to exit non-zero until the remaining external evidence is finalized.
35. `scripts/check-phase-5-shell-literal-safety.sh`
36. `scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence`

当前 SwiftPM test targets 覆盖：70 个 XCTest case 全部通过；Xcode 平台 gate 另覆盖 iOS app/UI tests 和 macOS app target tests。

Local gate command:

```sh
scripts/verify-phase-5-local.sh
```

Coverage: bash syntax checks, Phase 5 shell literal safety checks for checker pattern arrays, Phase 5 evidence directory cleanliness, static privacy logging audit, fixture JPEG generation smoke without Simulator import, SwiftPM tests, synthetic benchmark JSON smoke, and evidence generation with a captured baseline JSON path. It intentionally does not run real Photos authorization, seeded iOS Simulator media import, iOS UI tests, or macOS Xcode tests.

Phase 5 shell literal safety check:

```sh
scripts/check-phase-5-shell-literal-safety.sh
```

Coverage: statically rejects raw backticks in Phase 5 checker pattern arrays that Bash would execute as command substitution when the checker runs. Escaped Markdown backticks remain allowed for generated handoff text checks. It does not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, or edit evidence files.

Evidence directory cleanliness check:

```sh
scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence
```

Coverage: verifies the project Phase 5 evidence directory does not contain local smoke artifacts, temporary JSON files, or smoke-only manual/status folders after local verification runs. This keeps formal evidence references separate from verifier fixtures. It is read-only and does not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, or edit evidence files.

Verification document check:

```sh
scripts/check-phase-5-verification-doc.sh docs/Phase-5-Verification.md
```

Coverage: statically verifies that this verification document still lists the local evidence toolchain, external handoff/status helpers, finalization scripts, safety wording, completion claim boundary wording, host macOS Photos-backed evidence, macOS manual evidence, and SwiftData status. It does not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, or edit evidence files.

MVP Next completion audit:

```sh
scripts/audit-mvp-next-completion.sh \
  --plan docs/MVP-Next-Development-Plan.md \
  --product-spec docs/MVP-Product-Spec.md \
  --verification docs/Phase-5-Verification.md \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md \
  --date YYYY-MM-DD \
  --host-timestamp YYYYMMDD-HHMMSS
```

Coverage: runs a read-only whole-plan completion audit by chaining the verification document checker, Phase 5 shell literal safety checker, external evidence runbook checker, external evidence readiness preflight, handoff freshness checker, Phase 5 evidence directory cleanliness checker, Phase 5 status report with `--fail-on-incomplete`, final evidence completeness checker, and MVP Next whole-plan status checker with `--fail-on-incomplete`. When no evidence path, manual evidence directory, handoff, date, or host timestamp is supplied, the audit uses the latest existing Phase 5 evidence document, the matching manual evidence directory, the latest external handoff, the handoff Date, and the handoff host baseline timestamp, so the default audit command checks the active evidence package instead of a missing same-day shell. It remains non-zero while host macOS Photos-backed evidence, macOS manual evidence, evidence directory cleanliness, or final evidence rows are missing. It does not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, or edit evidence files.

External evidence runbook:

```sh
scripts/check-phase-5-external-runbook.sh docs/Phase-5-External-Evidence-Runbook.md
```

Coverage: statically checks `docs/Phase-5-External-Evidence-Runbook.md`, which records the remaining operator-only Phase 5 evidence sequence for host macOS Photos-backed 1k/10k/50k baseline JSON and the two macOS manual Photos screenshots. The checker ensures the runbook continues to include the guarded host baseline helper, macOS manual capture helper, write-back commands, final gates, completion claim boundary wording, Phase 5 shell literal safety gate and evidence template coverage through the whole-plan audit, non-production Photos warning, no-system-Delete warning, cancel-after-capture warning, sensitive-capture warning, no-Photos-read wording, and final completion condition. It does not read Photos libraries, capture screenshots, run benchmarks, or edit evidence.

External evidence readiness preflight:

```sh
scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-01 \
  --host-timestamp 20260601-photos-baseline
```

Coverage: runs the Phase 5 shell literal safety checker, external runbook checker, Phase 5 evidence directory cleanliness checker, validates the manual evidence folder skeleton, validates the host baseline capture helper against the recorded Passed preflight using the same deterministic host timestamp that the checklist and status report will print, rejects pre-existing host baseline JSON target paths before operator capture can collide with existing evidence, validates the macOS manual capture helper output, rejects pre-existing macOS capture target paths before operator screenshots can overwrite evidence, validates that the external checklist emits concrete macOS write-back paths plus the final evidence wrapper and whole-plan audit commands, validates Phase 5 shell literal safety gate, evidence template coverage, and evidence directory cleanliness coverage wording, and confirms the status report only asks for the expected remaining external evidence categories. In short, the external checklist emits concrete macOS write-back paths plus the final evidence wrapper, whole-plan audit commands, Phase 5 shell literal safety gate coverage wording, evidence template coverage wording, and evidence directory cleanliness coverage wording. It is read-only and does not read Photos libraries, launch apps, capture screenshots, run benchmarks, or edit evidence. Local smoke coverage rejects non filename-safe host timestamps, pre-existing host baseline JSON target paths, and pre-existing macOS capture target paths.

MVP Next status command:

```sh
scripts/report-mvp-next-development-status.sh \
  --plan docs/MVP-Next-Development-Plan.md \
  --product-spec docs/MVP-Product-Spec.md \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md \
  --date YYYY-MM-DD \
  --host-timestamp YYYYMMDD-HHMMSS
```

Coverage: prints a read-only whole-plan status by checking MVP plan/spec files, required phase sections and remaining-gap wording in `docs/MVP-Next-Development-Plan.md`, the product spec SwiftData/JSON persistence boundary in `docs/MVP-Product-Spec.md`, core package/app target structure, the Phase 5 evidence document, manual evidence directory, external evidence readiness, current handoff validity, Phase 5 evidence directory cleanliness, and the Phase 5 status report. When no evidence path, date, or host timestamp is supplied, the status report uses the latest existing docs/phase-5-evidence-YYYY-MM-DD.md file, the matching manual evidence directory when present, the Date recorded in the current handoff, and the host baseline timestamp recorded in the current handoff, so the default command does not report a missing same-day evidence shell when an active evidence package already exists. It exits non-zero with `--fail-on-incomplete` while Phase 5 still reports missing external evidence, the plan text omits the current Phase 5 gaps, the evidence directory cleanliness check fails, or the product spec omits the first-version SwiftData and JSON storage boundary decisions. It does not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, edit evidence files, or replace the heavier build/test gates.

External evidence handoff command:

```sh
scripts/create-phase-5-external-evidence-handoff.sh \
  --output docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md
```

Explicit reproducible form:

```sh
scripts/create-phase-5-external-evidence-handoff.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD \
  --date YYYY-MM-DD \
  --host-timestamp YYYYMMDD-HHMMSS \
  --output docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md
```

Coverage: runs the read-only external evidence readiness check, status report, and checklist, then renders a Markdown handoff with the current gaps, safety boundaries, completion claim boundary wording, exact operator commands, finalizer command, and whole-plan audit command plus whole-plan audit coverage wording. It requires a concrete --output path so the generated audit command can reference the actual handoff file instead of a placeholder. When evidence path, manual evidence directory, date, or host timestamp are omitted, the handoff generator uses the latest generated external handoff when present, then falls back to the latest Phase 5 evidence document and matching manual evidence directory, so default handoff generation stays aligned with the active evidence package. It does not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, or edit the evidence document. The generated Safety Boundary says: Do not recreate an existing manual evidence folder unless it is missing; the prepare script preserves an existing README so operator status notes are not overwritten. Local smoke coverage verifies the generated handoff includes deterministic host JSON naming, macOS manual evidence gaps, completion claim boundary wording, the final wrapper command, the whole-plan audit command, Phase 5 shell literal safety gate coverage, evidence template coverage, handoff freshness, evidence directory cleanliness and final evidence completeness coverage, and no placeholder host timestamp; invalid host timestamps, missing output paths, and default handoff generation that ignores the active evidence package are rejected.

External evidence handoff check:

```sh
scripts/check-phase-5-external-handoff.sh
scripts/check-phase-5-external-handoff.sh \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD \
  --date YYYY-MM-DD \
  --host-timestamp YYYYMMDD-HHMMSS
```

Coverage: statically verifies that a generated handoff still contains the expected read-only safety boundaries, readiness result, completion claim boundary wording, cancel-after-capture warning, host Photos baseline command, macOS manual evidence gaps, deterministic JSON filename, date-specific macOS capture command, finalizer command, whole-plan audit command, and whole-plan audit coverage wording for Phase 5 shell literal safety, evidence template coverage, handoff freshness, evidence directory cleanliness, final evidence completeness, and MVP plan/spec status. When no handoff path, evidence path, manual evidence directory, date, or host timestamp is supplied, the handoff checker uses the latest generated handoff and reads the evidence path, manual evidence directory, Date, and Host baseline timestamp fields from that handoff, so default handoff freshness checks stay aligned with the generated active evidence package. The completion claim boundary states that Phase 5 and the MVP Next Development Plan must not be marked complete until the host Photos-backed 1k/10k/50k baseline JSON and both macOS manual evidence artifacts are captured from non-production Photos libraries, written back, finalized, and accepted by the whole-plan audit. It rejects mismatched host timestamps, generated handoff checks that ignore the handoff Date or Host baseline timestamp, default handoff checks that ignore the latest generated handoff package, and placeholder `TBD`、`ARTIFACT`、or `YYYYMMDD-HHMMSS` text. The checker does not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, or edit evidence files.

Runtime privacy log audit command:

```sh
scripts/audit-runtime-privacy-logs.sh LOG_PATH [LOG_PATH ...]
```

Coverage: scans captured runtime or OS logs for fixture filenames, rendered fixture labels, local identifiers, Photos asset references, GPS/location fields, and arbitrary asset id/file path patterns. This complements the static source logging audit; manual verification still needs logs captured from non-production Photos runs.

Baseline capture command:

```sh
scripts/prepare-phase-5-host-baseline-capture.sh
scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS --date YYYY-MM-DD
scripts/capture-metadata-baseline.sh [--photos] [--validate-only] [--output DIR] [--timestamp ID] [asset-count ...]
```

Coverage: ensures `.build/debug/PickoBenchmarks` exists, invokes the direct executable so output remains pure JSON, validates the JSON contains benchmark rows, and writes timestamped raw evidence under `docs/phase-5-evidence/` by default. Use `--photos` only with a non-production Photos library; `--photos` requires the explicit `--confirm-non-production-photos` acknowledgement, a `--photos-library-label` value that says `Non-production`, the exact formal 1k/10k/50k count set, and an output directory under `docs/phase-5-evidence/`. `--timestamp` can pin the output JSON filename for evidence write-back and is restricted to filename-safe values. Existing baseline JSON files are never overwritten; rerunning with the same timestamp fails instead of replacing evidence. `--validate-only` checks those formal host Photos baseline arguments without building or reading the current Mac Photos library. Formal capture writes to a temporary JSON path first, validates mode, positive timing, expected asset-count rows, and the non-production label, then moves the file to the final deterministic evidence path only after validation passes. The host baseline capture helper validates that the target evidence document already records a Passed `--validate-only` preflight with a matching non-production label, then prints the formal capture, `update-phase-5-host-baseline.sh` write-back command, and date/timestamp-pinned status rerun command with the same deterministic baseline JSON path, without reading Photos libraries, building, running benchmarks, or editing evidence. When no evidence path or timestamp is supplied, the host baseline capture helper uses the latest existing Phase 5 evidence document and the host baseline timestamp recorded in the latest external handoff, so the default host baseline capture guide stays aligned with the active evidence package. The host baseline updater requires the formal `metadata-baseline-photos-1000-10000-50000-TIMESTAMP.json` filename before writing the final evidence rows, so ad hoc or hand-renamed JSON files cannot be recorded as the host baseline.

Manual evidence preparation command:

```sh
scripts/prepare-phase-5-manual-evidence.sh [--output DIR]
scripts/prepare-phase-5-macos-manual-capture.sh
scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir DIR --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD
scripts/check-phase-5-manual-evidence.sh --structure-only DIR
scripts/check-phase-5-manual-evidence.sh DIR
```

Coverage: creates a standard evidence folder with subdirectories and a README checklist for iOS authorization, limited library, delete confirmation, optional iOS Photos-backed benchmark operator captures, macOS authorization, macOS delete confirmation, and runtime privacy review. The prepare script preserves an existing README so operator status notes are not overwritten if the folder already exists. The macOS capture helper verifies the target evidence document exists, contains the two macOS Manual Photos Verification rows, and that the README still contains non-production, tight-capture, `screencapture -i`, no-system-Delete, and cancel-after-capture safety guidance, rejects pre-existing macOS screenshot target paths before printing capture commands, then prints the exact macOS screenshot paths plus `update-phase-5-manual-verification.sh` write-back commands without opening Photos, reading Photos libraries, launching Picko, capturing the screen, or editing the evidence file. When no evidence path or manual directory is supplied, the macOS capture helper uses the latest existing Phase 5 evidence document and the matching manual evidence directory, so the default macOS manual capture guide stays aligned with the active evidence package. The checker validates the generated skeleton in `--structure-only` mode and, in default mode, requires non-empty supported screenshot、recording、log、or text evidence files for the required manual interaction scenarios; text and log artifacts must pass `scripts/audit-runtime-privacy-logs.sh`. The `ios/metadata-benchmark` directory remains available for operator notes or optional captures, while final iOS benchmark completeness is enforced by the main evidence checker against the 1k、10k、50k benchmark rows and project evidence paths.

Platform gate command:

```sh
scripts/verify-phase-5-platform.sh
```

Coverage: iOS simulator build, iOS `PickoTests`, iOS `PickoUITests`, and macOS `PickoMac` app target tests. Script syntax has been checked with `bash -n`; full execution passed on 2026-05-31.

Evidence template command:

```sh
scripts/create-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md
scripts/create-phase-5-evidence.sh --baseline-json docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-YYYYMMDD-HHMMSS.json docs/phase-5-evidence-YYYY-MM-DD.md
scripts/check-phase-5-evidence-template.sh docs/Phase-5-Evidence-Template.md
```

Coverage: creates a structured evidence file from `docs/Phase-5-Evidence-Template.md`, prefilled with macOS, Xcode, architecture, and the standard Phase 5 evidence tables. The template includes a host Photos `Preflight status: TBD` row that must be changed to `Passed` only after the guarded `--validate-only` preflight has actually succeeded. The evidence template checker requires default helper commands before explicit reproducibility commands, requires the formal host Photos capture command to include deterministic `--timestamp YYYYMMDD-HHMMSS`, and rejects the legacy host capture command without `--timestamp`. When `--baseline-json` is provided, it fills the host Photos-backed metadata baseline rows and raw JSON path from a captured benchmark report. The evidence generator requires the same formal `docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-TIMESTAMP.json` baseline path used by the host baseline updater. The generator rejects synthetic or missing-mode JSON, incomplete 1k/10k/50k rows, non-positive benchmark values, and Photos-backed JSON with an ad hoc filename so controlled synthetic, partial, or hand-renamed output cannot be inserted as host Photos-backed evidence. Smoke generation to `/private/tmp/picko-phase-5-evidence-smoke.md` passed.

Evidence completeness check:

```sh
scripts/check-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md
```

Coverage: fails if the final evidence document still contains `TBD` or template placeholders, omits concrete Environment rows, omits `Non-production` from `Test Photos Library`, references production or personal Photos libraries, references missing local evidence files under `docs/phase-5-evidence/`, references temp JSON instead of project evidence JSON, omits a Photos baseline JSON, omits the complete host Photos baseline `--validate-only` preflight command with 1k、10k、50k counts and a non-production library label under `## Host Photos-Backed Metadata Baseline`, omits a `Preflight status: Passed` record in that host baseline section, references personal or production Photos libraries in that preflight label, references synthetic JSON instead of Photos-backed JSON, omits positive 1k、10k、50k benchmark rows from that JSON, omits iOS Photos-backed 1k、10k、50k evidence rows, points an iOS benchmark row at an empty or unsupported screenshot/recording artifact, omits a passing runtime privacy log audit reference under `## Privacy Review`, points that runtime privacy row at a missing or empty log artifact, rejects logs so runtime privacy logs with sensitive Photos patterns are not accepted as final evidence, omits any of the six Manual Photos Verification rows with `Passed` result/evidence path/concrete notes, points a manual verification row at the wrong scenario/platform evidence folder, points a manual verification row at a directory instead of a captured artifact file, points a manual verification row at an empty or unsupported file type instead of a screenshot、recording、log、or text artifact, includes sensitive photo metadata in a manual text/log artifact, writes a manual verification row with the wrong column count or table-breaking notes, references personal or production Photos libraries in manual notes, or omits a passing `scripts/check-phase-5-manual-evidence.sh` reference. `--allow-temp` exists only for local smoke tests. This checker only validates already captured evidence; it does not import simulator media, trigger Photos deletion, or read a Photos library.

Completeness gate recorder:

```sh
scripts/record-phase-5-completeness-gates.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md
```

Coverage: runs `scripts/check-phase-5-manual-evidence.sh`, verifies a temporary copy of the evidence document with the two final completeness rows prefilled, then updates `Evidence completeness` and `Manual evidence completeness` to `Passed` in the real evidence document. This avoids the circular dependency where `scripts/check-phase-5-evidence.sh` rejects `TBD` values before the final completeness rows can be recorded. `--artifact-prefix` must be concrete single-line text without `TBD` or Markdown table separators, so the final gate rows cannot be corrupted by placeholder or table-breaking operator notes. `--allow-temp` is restricted to temporary smoke evidence under `/tmp` or `/private/tmp`, so final project evidence cannot be marked complete with temp JSON references. Use this script only after all external Photos, benchmark, manual, and runtime privacy evidence has been captured.

Final evidence wrapper:

```sh
scripts/finalize-phase-5-evidence.sh
scripts/finalize-phase-5-evidence.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --date YYYY-MM-DD \
  --host-timestamp YYYYMMDD-HHMMSS
```

Coverage: runs the Phase 5 evidence directory cleanliness checker, runs the Phase 5 evidence template checker, runs the completeness gate recorder, then runs `scripts/report-phase-5-status.sh --fail-on-incomplete` and `scripts/check-phase-5-evidence.sh` against the same evidence document. This is the preferred final command after operator-only host Photos baseline and macOS manual evidence have been written back, because it records the final gates and immediately proves that no evidence gaps remain. `--host-timestamp` is passed through to the final status report so post-write-back guidance remains tied to the same host baseline JSON naming used during capture. When no evidence path, manual directory, date, or host timestamp is supplied, the finalizer uses the latest existing Phase 5 evidence document, the matching manual evidence directory, the Date recorded in the latest external handoff, and the host baseline timestamp recorded in the latest external handoff; in other words, the finalizer uses the host baseline timestamp recorded in the latest external handoff, so default finalizer status guidance stays aligned with the active evidence package. `--allow-temp` exists only for local smoke evidence under `/tmp` or `/private/tmp`; normal project evidence must pass without temp references. Local smoke coverage rejects placeholder artifact prefixes, incomplete evidence, non filename-safe host timestamps, default finalizer status guidance that ignores the latest handoff Date or handoff timestamp, finalizer defaults that fail to use the latest existing Phase 5 evidence document, stale evidence templates, and local smoke artifacts in the project evidence directory.

Phase 5 status report:

```sh
scripts/report-phase-5-status.sh
scripts/report-phase-5-status.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD --host-timestamp YYYYMMDD-HHMMSS
scripts/report-phase-5-status.sh --fail-on-incomplete
```

Coverage: prints a read-only status summary for final evidence readiness, Environment table rows, recorded automated gates, recorded static privacy checks, each Manual Photos Verification row, host Photos-backed baseline JSON referenced by the final evidence document, iOS Photos-backed benchmark rows, manual evidence folders, and runtime privacy log evidence. When no evidence path, date, or host timestamp is supplied, the status report uses the latest existing Phase 5 evidence document, the Date recorded in the latest external handoff, and the host baseline timestamp recorded in the latest external handoff, so default operator guidance stays tied to the same deterministic host baseline JSON naming and date-specific macOS capture paths. The status report does not treat stray JSON files under `docs/phase-5-evidence/` as ready unless the final evidence document references them. iOS benchmark reporting distinguishes a missing benchmark row from a row that references a missing, empty, or unsupported local screenshot or recording, so evidence write-back mistakes are easier to fix and empty or unsupported iOS benchmark artifacts are not reported ready. Manual verification rows are reported ready only when the row is `Passed`, references project manual evidence, has concrete notes, points at the expected scenario/platform folder, and the referenced artifact is a supported screenshot、recording、log、or text file, matching the final evidence checker. Runtime privacy log evidence is reported ready only when the `## Privacy Review` row references `scripts/audit-runtime-privacy-logs.sh`, the referenced project log artifact exists as a non-empty file, and that log passes `scripts/audit-runtime-privacy-logs.sh`, so empty runtime privacy logs are not reported ready and runtime privacy logs with sensitive Photos patterns are not reported ready. The next-required-evidence section is generated from the actual missing categories, puts the default active-package command sequence before explicit reproducibility commands, includes final evidence wrapper guidance after write-back, includes whole-plan audit guidance after write-back, includes default finalizer and whole-plan audit commands before explicit finalization reproducibility guidance, states that the whole-plan audit covers the Phase 5 shell literal safety gate, evidence template coverage, and evidence directory cleanliness, and includes final evidence document creation when no evidence file exists and Environment row write-back because unresolved Environment `TBD` values block the final evidence checker; when no gaps remain, the report prints a complete-state summary instead of external-evidence instructions and still prints the whole-plan completion audit command with the same Phase 5 shell literal safety, evidence template coverage, and evidence directory cleanliness coverage wording. Manual evidence is reported separately as structure prepared versus captured evidence complete, so an empty checklist folder cannot be mistaken for completed verification. `--date` controls the date emitted in macOS manual capture helper guidance, and `--host-timestamp` controls the host baseline timestamp emitted in checklist and all host baseline capture helper guidance so evidence operators can use deterministic JSON paths. Local smoke coverage rejects placeholder manual evidence guidance, non filename-safe host timestamps, unsupported iOS benchmark artifact readiness, empty runtime privacy log readiness, sensitive runtime privacy log readiness, default status output that ignores the latest handoff Date or handoff timestamp, and default status guidance that puts explicit commands before default active-package commands; it also checks timestamp guidance both before and after the host Photos preflight is recorded. It intentionally does not read Photos libraries, boot Simulator, import media, or trigger delete requests; `--fail-on-incomplete` is covered by local smoke tests and exits non-zero while evidence remains incomplete.

External evidence checklist:

```sh
scripts/phase-5-external-evidence-checklist.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD \
  --date YYYY-MM-DD \
  --host-timestamp YYYYMMDD-HHMMSS
```

Coverage: prints the remaining external evidence commands and write-back steps for host Photos-backed baseline, iOS Simulator benchmark evidence, manual Photos verification rows, runtime privacy logs, and final completeness gates. When no evidence path, manual directory, date, or host timestamp is supplied, the checklist uses the latest existing Phase 5 evidence document, the matching manual evidence directory, the Date recorded in the latest external handoff, and the host baseline timestamp recorded in the latest external handoff, so ad hoc operator runs stay aligned with the active evidence package. If the target evidence document does not exist yet, the checklist first prints the `scripts/create-phase-5-evidence.sh` command needed to create it. When the evidence document exists, the host baseline section inspects the referenced Photos-backed JSON, the complete guarded `--validate-only` preflight command, and a recorded `Preflight status: Passed` line under `## Host Photos-Backed Metadata Baseline`, then skips host capture/write-back steps once the non-production 1k、10k、50k baseline is already recorded. If the deterministic host baseline JSON target already exists for the requested `--host-timestamp` while the final evidence still needs host baseline capture, the external checklist warns the operator to choose a new timestamp or archive existing evidence before capture. The iOS benchmark section inspects the 1k、10k、50k rows and local artifact paths, then prints import and write-back commands only for the missing or incomplete counts; empty or unsupported iOS benchmark artifacts are treated as missing by the external checklist. Environment write-back steps are also generated from the actual missing rows, so a concrete iOS Simulator row is not requested again while the remaining non-production Test Photos Library row is still prompted. The checklist accepts `--date` so macOS manual capture and write-back paths are emitted with concrete date-specific filenames instead of placeholder screenshot paths, warns when date-specific macOS capture targets already exist so screenshots are not overwritten, and accepts `--host-timestamp` so host baseline capture、write-back、finalizer、and final status-report commands share a concrete JSON path; smoke coverage rejects placeholder macOS capture/write-back paths, placeholder host baseline timestamps, unsupported iOS benchmark evidence being skipped, empty runtime privacy logs being skipped, sensitive runtime privacy logs being skipped, missing host baseline JSON target collision warnings, missing pre-existing macOS capture target path warnings, and default checklist output that ignores the latest evidence package, handoff Date, or handoff timestamp. When the manual evidence directory already exists, the checklist reports that it is already prepared instead of telling the operator to recreate it, avoiding accidental README status-note loss. Runtime privacy write-back is skipped only when the audit reference is recorded under `## Privacy Review`, the referenced project log artifact exists as a non-empty file, and that log passes `scripts/audit-runtime-privacy-logs.sh`; empty runtime privacy logs are treated as missing by the external checklist and runtime privacy logs with sensitive Photos patterns are treated as missing by the external checklist. The final completeness section now prints default finalizer and whole-plan audit commands before explicit finalization reproducibility commands, states that the finalizer checks Phase 5 evidence directory cleanliness and the evidence template before recording final gates, and still prints the equivalent manual `record-phase-5-completeness-gates.sh` sequence for transparency; in other words, the finalizer followed by the whole-plan audit remains the preferred completion path. It explicitly states that the whole-plan audit covers the Phase 5 shell literal safety gate, evidence template coverage, and evidence directory cleanliness in both the pending-finalization and already-finalized branches; it skips finalization only when both `Evidence completeness` and `Manual evidence completeness` are recorded as `Passed` and their command columns reference the expected evidence checker scripts. It is read-only and intentionally does not read Photos libraries, boot Simulator, import media, delete assets, or edit evidence files.

Environment evidence updater:

```sh
scripts/update-phase-5-environment.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --field "iOS Simulator" \
  --value "iPhone MODEL, iOS VERSION, disposable Photos library"

scripts/update-phase-5-environment.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --field "Test Photos Library" \
  --value "Non-production simulator fixture and non-production Mac Photos library"
```

Coverage: updates the Environment table rows that otherwise remain `TBD` until external evidence capture. It accepts only known environment fields, rejects `TBD`, rejects table-breaking values, and requires `Test Photos Library` to explicitly say `Non-production` while rejecting production or personal library wording.

iOS benchmark evidence updater:

```sh
scripts/update-phase-5-ios-benchmark.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --count 10000 \
  --seconds 610.2500 \
  --rate 16.3867 \
  --path docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-YYYY-MM-DD.jpg
```

Coverage: updates exactly one iOS Simulator Photos-backed benchmark row in the final evidence document after a screenshot or recording has already been saved under `docs/phase-5-evidence/`. It validates the count set, positive timing values, and a non-empty screenshot or recording evidence path before editing the table, so empty captures cannot be recorded as benchmark evidence and unsupported artifact types cannot be recorded as benchmark evidence.

Automated gate evidence updater:

```sh
scripts/update-phase-5-gate.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --gate "Local Phase 5" \
  --result "Passed" \
  --artifact "Terminal run YYYY-MM-DD: scripts/verify-phase-5-local.sh"
```

Coverage: updates exactly one row in the Automated Gates table after the gate has actually been run. It accepts only known Phase 5 gate names, explicit `Passed`、`Failed`、`Blocked` results, and concrete single-line artifact text without `TBD` or Markdown table separators, so pending platform/manual/final-completeness gates remain visible instead of being accidentally filled and malformed gate evidence cannot corrupt the evidence table.

Privacy review evidence updater:

```sh
scripts/update-phase-5-privacy-review.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --check "Thumbnail cache remains in process memory only" \
  --result "Passed" \
  --artifact "Code review: Sources/PickoPhotos/PhotoThumbnailProvider.swift and Sources/PickoApp/Views/PickoThumbnailView.swift"
```

Coverage: updates exactly one row in the Privacy Review table. It accepts only known privacy checks, explicit `Passed`、`Failed`、`Blocked` results, and concrete single-line artifact text without `TBD` or Markdown table separators, so runtime log review remains pending until real non-production runtime/system logs have been captured and scanned and malformed artifact text cannot corrupt the evidence table.

Runtime privacy evidence recorder:

```sh
scripts/record-runtime-privacy-evidence.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --log docs/phase-5-evidence/privacy/runtime-ios-YYYY-MM-DD.log
```

Coverage: runs `scripts/audit-runtime-privacy-logs.sh` against one or more captured runtime/system logs and updates the runtime Privacy Review row only if the audit succeeds. Logs must live under `docs/phase-5-evidence/privacy/` and must come from non-production Photos runs.

Manual verification evidence updater:

```sh
scripts/update-phase-5-manual-verification.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --scenario "First Photos authorization" \
  --platform "iOS" \
  --result "Passed" \
  --path docs/phase-5-evidence/manual-YYYY-MM-DD/ios/authorization/authorization.png \
  --notes "Non-production Photos library"
```

Coverage: updates exactly one Manual Photos Verification row after the screenshot, recording, or log artifact has already been captured. It accepts only known scenario/platform pairs, explicit `Passed`、`Failed`、`Blocked` results, non-empty supported screenshot、recording、log、or text evidence file paths under `docs/phase-5-evidence/manual-*/`, text/log artifacts that pass the runtime privacy log audit, paths that match the expected scenario folder such as `macos/authorization` for macOS first authorization evidence, and concrete single-line notes without `TBD`、Markdown table separators、or personal/production Photos library wording.

Host baseline evidence updater:

```sh
scripts/update-phase-5-host-baseline.sh \
  --evidence docs/phase-5-evidence-YYYY-MM-DD.md \
  --baseline-json docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-YYYYMMDD-HHMMSS.json
```

Coverage: updates the Host Photos-Backed Metadata Baseline table and raw JSON path in an existing evidence document after the baseline has been captured. It requires the evidence document to already record both the complete host Photos `--validate-only` preflight command with 1k、10k、50k counts and a `Preflight status: Passed` line under `## Host Photos-Backed Metadata Baseline`, requires a non-production library label, rejects personal/production Photos wording in that preflight label, and rejects synthetic JSON, missing 1k/10k/50k rows, non-positive timing values, personal/production Photos wording in `photosLibraryLabel`, and JSON outside `docs/phase-5-evidence/`.

## 2. Metadata Indexing Baseline

### 2.1 Synthetic Controlled Fixture

命令：

```sh
swift run PickoBenchmarks
.build/debug/PickoBenchmarks --json 1000 10000 50000
```

环境：

| Field | Value |
| --- | --- |
| Mode | Synthetic fixture |
| OS | macOS 26.4, build 25E246 |
| Xcode | 26.5, build 17F42 |
| Architecture | arm64 |

结果：

| Asset count | Elapsed seconds | Assets / second |
| ---: | ---: | ---: |
| 1,000 | 0.0022 | 452,704.1554 |
| 10,000 | 0.0146 | 684,415.5802 |
| 50,000 | 0.0946 | 528,496.1506 |

说明：该结果验证 Picko metadata snapshot pipeline 的 controlled fixture 吞吐，不代表真实 Photos library I/O、iCloud 下载、权限弹窗或系统数据库延迟。

JSON evidence mode:

```sh
.build/debug/PickoBenchmarks --json 10
```

自检结果：命令输出纯 JSON，包含 `mode` 和 `rows[].assetCount/assetsPerSecond/elapsedSeconds`。如果使用 `swift run PickoBenchmarks --json ...`，SwiftPM 可能在 JSON 前输出 build 日志；机器解析时应优先直接调用 `.build/debug/PickoBenchmarks`。

### 2.2 Photos-Backed Fixture

待采集。Host macOS Photos baseline 应先使用 helper 打印与当前 active handoff 对齐的确定性命令：

```sh
scripts/prepare-phase-5-host-baseline-capture.sh
```

当前 handoff/status 对齐的显式命令为：

```sh
scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --label "Non-production Mac Photos test library" \
  --timestamp 20260601-photos-baseline \
  --date 2026-06-01

scripts/capture-metadata-baseline.sh \
  --photos \
  --confirm-non-production-photos \
  --photos-library-label "Non-production Mac Photos test library" \
  --timestamp 20260601-photos-baseline \
  1000 10000 50000
```

说明：`prepare-phase-5-host-baseline-capture.sh` 会验证 evidence 中已有的 `--validate-only` preflight，不会构建，也不会读取 Mac Photos library。正式命令运行 `.build/debug/PickoBenchmarks --photos --json`，读取的是 Mac Photos library，不读取 iOS Simulator Photos library，并把原始 JSON 保存到证据目录。运行前应准备非生产 Mac Photos 测试图库，或在专用测试账号/测试设备上运行；`--photos-library-label` 会写入 JSON 的 `photosLibraryLabel` 字段，后续 evidence checker 会要求该字段包含 `Non-production`。正式采集必须使用 status/handoff 输出的 deterministic `--timestamp`，避免生成与 write-back 和 audit 预期不一致的 JSON 文件名。

待填写结果：

| Asset count | Elapsed seconds | Assets / second | Environment |
| ---: | ---: | ---: | --- |
| 1,000 | TBD | TBD | Mac Photos-backed |
| 10,000 | TBD | TBD | Mac Photos-backed |
| 50,000 | TBD | TBD | Mac Photos-backed |

### 2.3 iOS Simulator Photos Fixture

用于 app-level Photos 授权、有限图库、缩略图和删除确认验收的受控媒体导入命令：

```sh
scripts/seed-simulator-photos-fixture.sh --count 1000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 10000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 50000 --simulator booted
```

For long imports, use smaller observable batches and explicit sorted index ranges:

```sh
scripts/seed-simulator-photos-fixture.sh --count 10000 --simulator booted --reuse --batch-size 100
scripts/seed-simulator-photos-fixture.sh --count 10000 --simulator booted --reuse --batch-size 100 --start-index 1100 --end-index 9999
scripts/import-simulator-photos-fixture-chunked.sh --count 10000 --simulator booted --chunk-size 500 --batch-size 100
scripts/import-simulator-photos-fixture-chunked.sh --count 10000 --simulator booted --chunk-size 500 --batch-size 100 --max-chunks 2
```

脚本自检：

```sh
scripts/seed-simulator-photos-fixture.sh --help
scripts/seed-simulator-photos-fixture.sh --count 3 --output /private/tmp/picko-fixture-smoke --generate-only
file /private/tmp/picko-fixture-smoke/picko-fixture-00000.jpg
```

自检结果：

1. `--help` 正常输出用法。
2. `--generate-only` 成功生成 3 个 JPEG。
3. `file` 确认为 JPEG image data。
4. `--reuse` 支持恢复部分已生成的 fixture 文件；生成阶段每 500 张输出进度。
5. 导入阶段支持 `--batch-size`、`--start-index` 和 `--end-index`，每批输出进度，便于长导入分段取证。
6. `scripts/import-simulator-photos-fixture-chunked.sh` 可按 checkpoint 分段导入，成功一段就记录下一个 sorted index，适合 10k/50k 长跑窗口续跑；`--max-chunks` 可限制单次导入窗口，避免一次命令必须跑完整个测试图库。

前置条件：

1. Simulator 必须先 boot。
2. 目标 simulator Photos library 应只包含非生产测试资产，或在导入前重置为可丢弃状态。
3. 50k 导入会生成大量临时 JPEG，默认保存在 ignored `BenchmarkFixtures/` 目录；确认磁盘空间后再运行。
4. 当前已提供 iOS app 内 benchmark trigger；使用 `--picko-run-metadata-benchmark` 可启动 benchmark screen，默认 Photos-backed 模式，加入 `--picko-benchmark-synthetic` 可用 synthetic fixture 做 UI smoke。
5. 10k fixture 已在 `iPhone 17 Pro` simulator 上通过 `/private/tmp/picko-benchmark-fixtures/photos-10000` 完整导入，并采集 Photos-backed in-app benchmark evidence。
6. 50k fixture 已通过 `/private/tmp/picko-benchmark-fixtures/photos-50000` 完整生成 50,000 个非生产 JPEG。生成器已在每张图片绘制/编码时使用 `autoreleasepool`，避免长跑 AppKit 临时对象累积导致进程被 kill。
7. 50k simulator 导入已通过 `scripts/import-simulator-photos-fixture-chunked.sh` 完成，checkpoint 文件 `/private/tmp/picko-benchmark-fixtures/photos-50000/import.checkpoint` 的值为 `50000`。50k Photos-backed in-app benchmark evidence 已采集。

### 2.4 iOS In-App Benchmark Trigger

Synthetic smoke 已验证：

```sh
xcodebuild test -scheme Picko -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PickoUITests
```

UI test launch arguments:

```text
--picko-run-metadata-benchmark --picko-benchmark-synthetic --picko-benchmark-counts=10
```

稳定取证标识：

1. `metadata-benchmark-summary`: summary 文本，格式为 `Mode: Synthetic; 10: 0.2500s, 40.0000 assets/s`。
2. `metadata-benchmark-result-{count}`: 单个档位结果行，例如 `metadata-benchmark-result-10`。
3. `metadata-benchmark-error`: 安全错误文本；Photos 授权失败只显示授权类别，benchmark 运行失败只显示测试图库设置/重试提示，不输出底层错误内容或照片 metadata。

Photos-backed simulator timing 进度：

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | 58.9891 | 16.9523 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg` |
| 10,000 | 26.3797 | 379.0787 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-2026-05-31.jpg` |
| 50,000 | 331.2685 | 150.9350 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-50000-2026-05-31.jpg` |

准备方式：

1. Boot target iOS Simulator.
2. Seed non-production media with `scripts/seed-simulator-photos-fixture.sh`.
3. Launch Picko with `--picko-run-metadata-benchmark --picko-benchmark-counts=1000,10000,50000`.
4. Grant Photos access when prompted.
5. Record the visible result rows or query `metadata-benchmark-summary` from the `Metadata Benchmark` screen.
6. Save the screenshot or recording under `docs/phase-5-evidence/ios-metadata-benchmark/`.
7. Use `scripts/update-phase-5-ios-benchmark.sh` to update the final evidence document row for the captured count.

## 3. Delete Confirmation Boundary

Automated iOS UI smoke verified:

```sh
xcodebuild test -scheme Picko -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PickoUITests
```

Sample basket launch argument:

```text
--picko-use-sample-basket
```

Verified behavior:

1. App opens directly to `Basket`.
2. Basket shows `1 items waiting for review`.
3. `Confirm with Photos` is disabled when no real Photos deleter is attached.
4. `Clear basket` remains enabled.
5. Global `Clear Picko State` flow resets the sample basket to `0 items waiting for review`.
6. Clearing Picko state keeps `Confirm with Photos` disabled when no real Photos deleter is attached, so the local-state reset path does not trigger Photos confirmation.

## 4. Manual Photos Verification

当前取证状态：

1. iOS 首次 Photos 授权：已采集 `docs/phase-5-evidence/manual-2026-05-31/ios/authorization/ios-first-photos-authorization-2026-05-31.jpg`。
2. iOS limited library 状态：已采集 `docs/phase-5-evidence/manual-2026-05-31/ios/limited-library/ios-limited-library-picker-2026-05-31.jpg`。
3. iOS 预删除篮触发 Photos 系统删除确认：已采集 `docs/phase-5-evidence/manual-2026-05-31/ios/delete-confirmation/ios-system-photos-delete-confirmation-2026-05-31.jpg`，未点击系统 `Delete`。
4. 删除后系统 Photos “Recently Deleted”可恢复说明：Picko 确认文案截图已采集 `docs/phase-5-evidence/manual-2026-05-31/ios/delete-confirmation/ios-picko-confirmation-recently-deleted-2026-05-31.jpg`。
5. macOS 首次 Photos 授权：仍待非生产 Mac Photos library 截图或录屏。
6. macOS 预删除篮触发 Photos 系统删除确认：仍待非生产 Mac Photos library 截图或录屏。

macOS 手工取证建议：

1. 授权截图保存到 `docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-01.png`。
2. 删除确认截图保存到 `docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-01.png`。
3. 系统提示可见后可用 `screencapture -i PATH` 手动选择窗口或区域；不要捕获个人照片缩略图、人脸、文件名、地图/位置细节或 Finder 路径。
4. 删除确认取证只停在 Photos 系统确认弹窗，不能点击系统 `Delete`。

取证目录准备：

```sh
scripts/prepare-phase-5-manual-evidence.sh
```

Automated denied-access fallback verified:

```text
--picko-use-denied-library
```

Verified behavior:

1. App shows `Photo library access is needed to review your library.`
2. App shows `Review Sample Library` fallback action.

macOS denied-access launch path added:

```text
--picko-use-denied-library
```

Automated coverage:

1. `PickoMacLibraryBootstrapView` can be constructed with a denied bootstrapper.
2. `PickoMac` app target builds and tests with the denied launch path available.

## 5. Privacy Notes

当前自动验证已经覆盖：

1. 删除请求只能从预删除篮确认链路触发。
2. 删除协议只接收 queued asset ids。
3. 用户可清空 Picko 本地 review decision、session、group decision 和 basket records；该路径只清理内存状态和 SwiftData 记录，不调用 Photos 删除协议。
4. 缩略图缓存为进程内存缓存，Picko 不主动写入缩略图到磁盘。
5. `scripts/audit-privacy-logging.sh` confirms product code under `Sources/` and `Apps/` has no broad `print`、`debugPrint`、`dump`、`Logger`、`os_log`、`NSLog` logging calls.
6. `scripts/audit-runtime-privacy-logs.sh` is available to scan captured runtime/system logs for sensitive Photos patterns.

当前取证状态：

1. 已使用非生产 iOS Simulator Photos fixture 捕获 runtime log：`docs/phase-5-evidence/privacy/ios-runtime-2026-05-31.log`。
2. 已用 `scripts/audit-runtime-privacy-logs.sh docs/phase-5-evidence/privacy/ios-runtime-2026-05-31.log` 扫描，未发现敏感 Photos pattern。
3. 已使用 `scripts/record-runtime-privacy-evidence.sh` 写入最终 evidence 文档。
4. macOS runtime/system logs are optional supplemental artifacts unless `scripts/report-phase-5-status.sh` or `scripts/check-phase-5-evidence.sh` starts requiring them again; the current blocking macOS evidence is the first authorization screenshot/recording and the pre-delete basket to Photos confirmation screenshot/recording.
