#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/audit-runtime-privacy-logs.sh LOG_PATH [LOG_PATH ...]

Scans runtime or system logs captured during manual Photos verification for
photo contents, fixture filenames, local identifiers, and sensitive metadata
patterns. Pass only logs from non-production Photos test runs.
USAGE
}

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 64
fi

pattern='picko-fixture-[0-9]+\.jpg|Picko [0-9]{1,6}|localIdentifier|PHAsset|latitude|longitude|GPS|CLLocation|assetIds?[:=]|file(name|URL|Path)'

for log_path in "$@"; do
  if [[ "$log_path" == "--help" || "$log_path" == "-h" ]]; then
    usage
    exit 0
  fi

  if [[ ! -f "$log_path" ]]; then
    echo "Missing log file: $log_path" >&2
    exit 66
  fi

  if rg --line-number --color never -i "$pattern" "$log_path"; then
    cat >&2 <<'MESSAGE'

Runtime privacy log audit failed.
Review the matched lines and remove or narrow logging before using real Photos
assets. Runtime evidence should not contain photo contents, filenames, local
identifiers, GPS/location metadata, or arbitrary asset id lists.
MESSAGE
    exit 1
  fi
done

echo "Runtime privacy log audit passed: no sensitive photo patterns found."
