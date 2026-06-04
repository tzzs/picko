#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/import-simulator-photos-fixture-chunked.sh --count N --simulator ID [options]

Options:
  --count N          Total fixture count. Required.
  --simulator ID     Simulator UDID, name, or "booted". Required.
  --output DIR       Fixture directory. Defaults to BenchmarkFixtures/photos-N.
  --chunk-size N     Number of sorted fixture indexes per checkpointed chunk. Defaults to 500.
  --batch-size N     Number of assets per simctl addmedia call. Defaults to 100.
  --checkpoint PATH  Checkpoint file. Defaults to OUTPUT/import.checkpoint.
  --from-index N     Override checkpoint and start importing at this sorted index.
  --max-chunks N     Stop after N successful chunks so long imports can be resumed later.
  --generate-only    Generate or resume fixture files without importing them.
  --help             Show this help.

The checkpoint stores the next sorted fixture index to import after each
successful chunk. Use a disposable simulator Photos library for benchmark runs.
USAGE
}

count=""
simulator=""
output=""
chunk_size=500
batch_size=100
checkpoint=""
from_index=""
max_chunks=""
generate_only=0
imported_chunks=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --count)
      count="${2:-}"
      shift 2
      ;;
    --simulator)
      simulator="${2:-}"
      shift 2
      ;;
    --output)
      output="${2:-}"
      shift 2
      ;;
    --chunk-size)
      chunk_size="${2:-}"
      shift 2
      ;;
    --batch-size)
      batch_size="${2:-}"
      shift 2
      ;;
    --checkpoint)
      checkpoint="${2:-}"
      shift 2
      ;;
    --from-index)
      from_index="${2:-}"
      shift 2
      ;;
    --max-chunks)
      max_chunks="${2:-}"
      shift 2
      ;;
    --generate-only)
      generate_only=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ -z "$count" || ! "$count" =~ ^[0-9]+$ || "$count" -le 0 ]]; then
  echo "--count must be a positive integer." >&2
  usage >&2
  exit 64
fi

if [[ -z "$simulator" ]]; then
  echo "--simulator is required." >&2
  usage >&2
  exit 64
fi

if [[ -z "$chunk_size" || ! "$chunk_size" =~ ^[0-9]+$ || "$chunk_size" -le 0 ]]; then
  echo "--chunk-size must be a positive integer." >&2
  usage >&2
  exit 64
fi

if [[ -z "$batch_size" || ! "$batch_size" =~ ^[0-9]+$ || "$batch_size" -le 0 ]]; then
  echo "--batch-size must be a positive integer." >&2
  usage >&2
  exit 64
fi

if [[ -n "$from_index" && ! "$from_index" =~ ^[0-9]+$ ]]; then
  echo "--from-index must be a non-negative integer." >&2
  usage >&2
  exit 64
fi

if [[ -n "$max_chunks" && (! "$max_chunks" =~ ^[0-9]+$ || "$max_chunks" -le 0) ]]; then
  echo "--max-chunks must be a positive integer." >&2
  usage >&2
  exit 64
fi

if [[ -z "$output" ]]; then
  output="BenchmarkFixtures/photos-${count}"
fi

if [[ -z "$checkpoint" ]]; then
  checkpoint="$output/import.checkpoint"
fi

mkdir -p "$output"

scripts/seed-simulator-photos-fixture.sh \
  --count "$count" \
  --output "$output" \
  --reuse \
  --generate-only

if [[ "$generate_only" -eq 1 ]]; then
  echo "Generated fixture files in $output"
  exit 0
fi

if [[ -n "$from_index" ]]; then
  next_index="$from_index"
elif [[ -f "$checkpoint" ]]; then
  next_index="$(tr -d '[:space:]' < "$checkpoint")"
else
  next_index=0
fi

if [[ -z "$next_index" || ! "$next_index" =~ ^[0-9]+$ || "$next_index" -gt "$count" ]]; then
  echo "Invalid checkpoint next index: $next_index" >&2
  exit 65
fi

while [[ "$next_index" -lt "$count" ]]; do
  end_index=$((next_index + chunk_size - 1))
  if [[ "$end_index" -ge "$count" ]]; then
    end_index=$((count - 1))
  fi

  echo "Importing checkpointed chunk: ${next_index}-${end_index} of $count"
  scripts/seed-simulator-photos-fixture.sh \
    --count "$count" \
    --simulator "$simulator" \
    --output "$output" \
    --reuse \
    --batch-size "$batch_size" \
    --start-index "$next_index" \
    --end-index "$end_index"

  next_index=$((end_index + 1))
  printf '%s\n' "$next_index" > "$checkpoint"
  echo "Checkpoint updated: next index $next_index"

  imported_chunks=$((imported_chunks + 1))
  if [[ -n "$max_chunks" && "$imported_chunks" -ge "$max_chunks" ]]; then
    echo "Reached --max-chunks $max_chunks; resume later from checkpoint index $next_index"
    exit 0
  fi
done

echo "Completed import for $count assets from $output"
