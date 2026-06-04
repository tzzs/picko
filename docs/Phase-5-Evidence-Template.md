# Picko Phase 5 Evidence

日期：YYYY-MM-DD
工作目录：`/Users/tanzz/workspaces/picko/.worktrees/mvp-core`

## Environment

| Field | Value |
| --- | --- |
| macOS | __ENV_MACOS__ |
| Xcode | __ENV_XCODE__ |
| Architecture | __ENV_ARCHITECTURE__ |
| iOS Simulator | TBD |
| Test Photos Library | Non-production / TBD |

## Automated Gates

| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| Local Phase 5 | `scripts/verify-phase-5-local.sh` | TBD | TBD |
| Platform Phase 5 | `scripts/verify-phase-5-platform.sh` | TBD | TBD |
| Privacy logging | `scripts/audit-privacy-logging.sh` | TBD | TBD |
| Evidence completeness | `scripts/check-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md` | TBD | TBD |
| Manual evidence completeness | `scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-YYYY-MM-DD` | TBD | TBD |

## Host Photos-Backed Metadata Baseline

Command:

```sh
scripts/prepare-phase-5-host-baseline-capture.sh
scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS --date YYYY-MM-DD
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS 1000 10000 50000
```

Preflight status: TBD

| Asset count | Elapsed seconds | Assets / second | Notes |
| ---: | ---: | ---: | --- |
| 1,000 | __HOST_PHOTOS_1000_SECONDS__ | __HOST_PHOTOS_1000_RATE__ | __HOST_PHOTOS_1000_NOTES__ |
| 10,000 | __HOST_PHOTOS_10000_SECONDS__ | __HOST_PHOTOS_10000_RATE__ | __HOST_PHOTOS_10000_NOTES__ |
| 50,000 | __HOST_PHOTOS_50000_SECONDS__ | __HOST_PHOTOS_50000_RATE__ | __HOST_PHOTOS_50000_NOTES__ |

Raw JSON evidence path: `__HOST_PHOTOS_JSON_PATH__`

## iOS Simulator Photos-Backed Benchmark

Fixture setup:

```sh
scripts/seed-simulator-photos-fixture.sh --count 1000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 10000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 50000 --simulator booted
```

App launch arguments:

```text
--picko-run-metadata-benchmark --picko-benchmark-counts=1000,10000,50000
```

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | TBD | TBD | TBD |
| 10,000 | TBD | TBD | TBD |
| 50,000 | TBD | TBD | TBD |

Screenshot or recording path: `TBD`

## Manual Photos Verification

Prepare evidence folders:

```sh
scripts/prepare-phase-5-manual-evidence.sh
scripts/prepare-phase-5-macos-manual-capture.sh
scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD
scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-YYYY-MM-DD
```

| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | TBD | TBD | TBD |
| Limited library state | iOS | TBD | TBD | TBD |
| Pre-delete basket triggers Photos confirmation | iOS | TBD | TBD | TBD |
| First Photos authorization | macOS | TBD | TBD | TBD |
| Pre-delete basket triggers Photos confirmation | macOS | TBD | TBD | TBD |
| Recently Deleted recovery explanation | iOS/macOS | TBD | TBD | TBD |

## Privacy Review

| Check | Result | Evidence |
| --- | --- | --- |
| Product code has no broad logging calls | TBD | `scripts/audit-privacy-logging.sh` |
| Runtime logs checked for photo contents or sensitive metadata | TBD | `scripts/audit-runtime-privacy-logs.sh docs/phase-5-evidence/privacy/LOG_PATH` / TBD |
| Thumbnail cache remains in process memory only | TBD | Code review / TBD |
