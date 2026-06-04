#!/usr/bin/env bash
set -euo pipefail

search_paths=(Sources Apps)
pattern='print\(|debugPrint\(|dump\(|Logger\(|os_log|NSLog'

if rg --line-number --color never "$pattern" "${search_paths[@]}"; then
  cat >&2 <<'MESSAGE'

Privacy logging audit failed.
Avoid logging photo contents, local identifiers, or sensitive metadata from product code.
If logging is intentionally added later, document the privacy boundary and narrow the scan.
MESSAGE
  exit 1
fi

echo "Privacy logging audit passed: no product logging calls found in Sources/ or Apps/."
