# Picko Phase 5 External Evidence Runbook

日期：2026-06-01
工作目录：`/Users/tanzz/workspaces/picko/.worktrees/mvp-core`

This runbook covers the remaining Phase 5 evidence that cannot be completed by
local smoke tests alone. Use only non-production Photos libraries and simulator
media. Do not capture personal photos, faces, filenames, map/location details,
Finder paths, or sensitive metadata.

## 1. Current Remaining Evidence

As of the current status report, the remaining external evidence is:

1. Host macOS Photos-backed 1k/10k/50k metadata indexing baseline JSON.
2. macOS first Photos authorization screenshot or recording.
3. macOS pre-delete basket to Photos system delete confirmation screenshot or recording.

The following evidence is already recorded and should not be repeated unless the
environment changes: iOS first authorization, iOS limited library, iOS delete
confirmation, iOS Photos-backed benchmark rows, runtime privacy log audit, local
verification gates, platform verification gates, and privacy logging gates.

## 2. Preflight Status Check

Run the read-only status report first:

```sh
scripts/report-phase-5-status.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --date 2026-06-01 \
  --host-timestamp 20260601-photos-baseline
```

Expected remaining items should be limited to host Photos-backed baseline and
the two macOS manual verification rows. If the report asks for broader missing
items, fix those first before collecting Photos evidence.

To create a single operator handoff with the current status, safety guardrails,
and exact checklist commands, prefer the default active-package form:

Default handoff generation:

```sh
scripts/create-phase-5-external-evidence-handoff.sh \
  --output docs/phase-5-evidence/phase-5-external-handoff-2026-06-01.md
```

This uses the latest generated external handoff when present, then falls back to
the latest Phase 5 evidence document and matching manual evidence directory, so
default handoff generation aligned with the active evidence package remains the
normal operator path.

For explicit reproducibility, run:

```sh
scripts/create-phase-5-external-evidence-handoff.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-01 \
  --host-timestamp 20260601-photos-baseline \
  --output docs/phase-5-evidence/phase-5-external-handoff-2026-06-01.md
```

The handoff generator is read-only with respect to Photos and the evidence
tables: it runs the readiness check, status report, and checklist, then writes a
Markdown handoff. It does not read Photos libraries, launch apps, capture
screenshots, run benchmarks, delete assets, or edit the evidence document.
The generated handoff must include a completion claim boundary and the
cancel-after-capture safety warning: Phase 5 and the
MVP Next Development Plan are not complete until the host Photos-backed 1k/10k/50k
baseline JSON and both macOS manual evidence artifacts are captured from
non-production Photos libraries, written back to the evidence document, finalized,
and accepted by the whole-plan audit. In checklist terms: Phase 5 and the MVP
Next Development Plan are not complete until the host Photos-backed 1k/10k/50k
baseline JSON, both macOS manual evidence artifacts, the finalizer, and the
whole-plan audit are all complete.

Verify the generated handoff before handing it to an operator:

```sh
scripts/check-phase-5-external-handoff.sh
```

Explicit reproducibility:

```sh
scripts/check-phase-5-external-handoff.sh \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-01.md \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-01 \
  --host-timestamp 20260601-photos-baseline
```

## 3. Host Photos-Backed Baseline

Requirements:

1. Use a prepared non-production Mac Photos test library.
2. Do not run the capture command against a production or personal Photos library.
3. Keep the library label exactly aligned with the preflight already recorded in
   the evidence document.

First print the active-package guarded capture commands:

```sh
scripts/prepare-phase-5-host-baseline-capture.sh
```

Explicit reproducibility:

```sh
scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --label "Non-production Mac Photos test library" \
  --timestamp 20260601-photos-baseline \
  --date 2026-06-01
```

This helper validates the recorded `Passed` preflight and does not read Photos
libraries, build, run benchmarks, or edit evidence.

Then run the formal capture only when the non-production Mac Photos library is
active:

```sh
scripts/capture-metadata-baseline.sh \
  --photos \
  --confirm-non-production-photos \
  --photos-library-label "Non-production Mac Photos test library" \
  --timestamp 20260601-photos-baseline \
  1000 10000 50000
```

Write the captured JSON back to the evidence document:

```sh
scripts/update-phase-5-host-baseline.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --baseline-json docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-20260601-photos-baseline.json
```

## 4. macOS Manual Photos Evidence

Requirements:

1. Use only a non-production Mac Photos library.
2. Keep screenshots tight around the prompt or confirmation.
3. Do not capture personal photo thumbnails, faces, filenames, map/location
   details, Finder paths, or sensitive metadata.
4. Do not click the system Delete button while collecting delete-confirmation
   evidence.
5. After capturing delete-confirmation evidence, press Escape or click Cancel to
   dismiss the system confirmation without deleting assets.

The active manual evidence folder is already prepared at
`docs/phase-5-evidence/manual-2026-05-31`. Do not recreate it unless the folder is missing.
If it must be prepared again, use `scripts/prepare-phase-5-manual-evidence.sh`;
that script preserves an existing README so operator status notes are not overwritten.

Print the active-package macOS capture guide first:

```sh
scripts/prepare-phase-5-macos-manual-capture.sh
```

Explicit reproducibility:

```sh
scripts/prepare-phase-5-macos-manual-capture.sh \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --date 2026-06-01
```

This helper validates the manual evidence README safety guidance and does not
open Photos, read Photos libraries, launch Picko, capture the screen, or edit
evidence.

After the relevant system prompt is visible, capture the two remaining artifacts:

```sh
screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-01.png
screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-01.png
```

Validate the manual evidence folder:

```sh
scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-2026-05-31
```

Write the macOS rows back to the evidence document:

```sh
scripts/update-phase-5-manual-verification.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-01.png \
  --notes "Non-production Mac Photos library first authorization prompt captured"

scripts/update-phase-5-manual-verification.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --scenario "Pre-delete basket triggers Photos confirmation" \
  --platform "macOS" \
  --result "Passed" \
  --path docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-01.png \
  --notes "Non-production Mac Photos library system delete confirmation captured without clicking Delete"
```

## 5. Final Gates

After the host baseline JSON and macOS manual evidence rows are recorded, use
the default active-package finalization path first:

Default finalization command:

```sh
scripts/finalize-phase-5-evidence.sh
scripts/audit-mvp-next-completion.sh
```

Explicit finalization reproducibility:

```sh
scripts/finalize-phase-5-evidence.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --date 2026-06-01 \
  --host-timestamp 20260601-photos-baseline

scripts/audit-mvp-next-completion.sh \
  --plan docs/MVP-Next-Development-Plan.md \
  --product-spec docs/MVP-Product-Spec.md \
  --verification docs/Phase-5-Verification.md \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-01.md \
  --date 2026-06-01 \
  --host-timestamp 20260601-photos-baseline
```

The finalizer checks the Phase 5 evidence directory cleanliness and evidence
template, records the two final completeness gates, runs the status report with
`--fail-on-incomplete`, and runs the final evidence checker. The whole-plan
completion audit then verifies that the final claim also covers the MVP plan,
product spec SwiftData/JSON persistence boundary, Phase 5 shell literal safety
gate, evidence template coverage, runbook, handoff, evidence directory
cleanliness, and evidence status together.

The equivalent manual evidence sequence before the whole-plan audit is:

```sh
scripts/record-phase-5-completeness-gates.sh --evidence docs/phase-5-evidence-2026-05-31.md
scripts/report-phase-5-status.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-01 --host-timestamp 20260601-photos-baseline --fail-on-incomplete
scripts/check-phase-5-evidence.sh docs/phase-5-evidence-2026-05-31.md
```

The goal is complete only when the status report prints no remaining evidence
gaps, the final evidence checker passes, the Phase 5 shell literal safety gate is
covered by the whole-plan audit, the evidence template coverage gate is covered
by the whole-plan audit, and the whole-plan completion audit passes.
