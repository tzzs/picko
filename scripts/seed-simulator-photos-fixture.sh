#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/seed-simulator-photos-fixture.sh --count 1000 [--simulator booted] [--output BenchmarkFixtures/photos-1000]

Generates deterministic JPEG test assets and imports them into an iOS Simulator
Photos library with xcrun simctl addmedia.

Options:
  --count N       Number of JPEG assets to generate. Required.
  --simulator ID  Simulator UDID, name, or "booted". Defaults to "booted".
  --output DIR    Output directory for generated assets. Defaults to BenchmarkFixtures/photos-N.
  --reuse         Reuse existing generated assets when the expected count already exists.
  --batch-size N  Number of assets per simctl addmedia call. Defaults to 200.
  --start-index N First sorted fixture index to import. Defaults to 0.
  --end-index N   Last sorted fixture index to import. Defaults to count - 1.
  --generate-only Generate the JPEG assets without importing them into Simulator.
  --help          Show this help.
USAGE
}

count=""
simulator="booted"
output=""
reuse=0
generate_only=0
batch_size=200
start_index=0
end_index=""

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
    --reuse)
      reuse=1
      shift
      ;;
    --batch-size)
      batch_size="${2:-}"
      shift 2
      ;;
    --start-index)
      start_index="${2:-}"
      shift 2
      ;;
    --end-index)
      end_index="${2:-}"
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

if [[ -z "$batch_size" || ! "$batch_size" =~ ^[0-9]+$ || "$batch_size" -le 0 ]]; then
  echo "--batch-size must be a positive integer." >&2
  usage >&2
  exit 64
fi

if [[ -z "$start_index" || ! "$start_index" =~ ^[0-9]+$ ]]; then
  echo "--start-index must be a non-negative integer." >&2
  usage >&2
  exit 64
fi

if [[ -z "$end_index" ]]; then
  end_index=$((count - 1))
fi

if [[ ! "$end_index" =~ ^[0-9]+$ ]]; then
  echo "--end-index must be a non-negative integer." >&2
  usage >&2
  exit 64
fi

if [[ "$start_index" -gt "$end_index" || "$end_index" -ge "$count" ]]; then
  echo "Import range must satisfy 0 <= start-index <= end-index < count." >&2
  usage >&2
  exit 64
fi

if [[ -z "$output" ]]; then
  output="BenchmarkFixtures/photos-${count}"
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "swift is required to generate fixture images." >&2
  exit 69
fi

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/picko-clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

mkdir -p "$output"

existing_count=$(find "$output" -maxdepth 1 -name 'picko-fixture-*.jpg' | wc -l | tr -d ' ')
if [[ "$reuse" -eq 1 && "$existing_count" == "$count" ]]; then
  echo "Reusing $existing_count JPEG assets in $output"
else
  if [[ "$reuse" -eq 1 && "$existing_count" -gt 0 ]]; then
    echo "Resuming fixture generation with $existing_count existing JPEG assets in $output"
  else
    rm -f "$output"/picko-fixture-*.jpg
  fi

  swift_source="$(mktemp "${TMPDIR:-/tmp}/picko-fixture-generator.XXXXXX.swift")"
  trap 'rm -f "$swift_source"' EXIT

  cat > "$swift_source" <<'SWIFT'
import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3,
      let count = Int(arguments[1]),
      count > 0 else {
    FileHandle.standardError.write(Data("Usage: generator COUNT OUTPUT_DIR\n".utf8))
    exit(64)
}

let outputURL = URL(fileURLWithPath: arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let width = 640
let height = 480

for index in 0..<count {
    if index > 0 && index % 500 == 0 {
        FileHandle.standardError.write(Data("Generated \(index) of \(count) fixture images\n".utf8))
    }

    let fileURL = outputURL.appendingPathComponent(String(format: "picko-fixture-%05d.jpg", index))
    if FileManager.default.fileExists(atPath: fileURL.path) {
        continue
    }

    try autoreleasepool {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()

        let hue = CGFloat((index * 37) % 360) / 360
        NSColor(calibratedHue: hue, saturation: 0.62, brightness: 0.88, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        NSColor(calibratedHue: 1 - hue, saturation: 0.35, brightness: 0.55, alpha: 1).setFill()
        let inset = CGFloat(24 + (index % 96))
        NSBezierPath(ovalIn: NSRect(x: inset, y: inset, width: CGFloat(width) - inset * 2, height: CGFloat(height) - inset * 2)).fill()

        let label = "Picko \(index)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 42, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        label.draw(at: NSPoint(x: 28, y: 28), withAttributes: attributes)
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
            FileHandle.standardError.write(Data("Failed to render fixture \(index)\n".utf8))
            exit(70)
        }

        try jpeg.write(to: fileURL, options: .atomic)
    }
}

FileHandle.standardError.write(Data("Generated \(count) of \(count) fixture images\n".utf8))
SWIFT

  swift "$swift_source" "$count" "$output"
fi

media_files=()
while IFS= read -r media_file; do
  media_files+=("$media_file")
done < <(find "$output" -maxdepth 1 -name 'picko-fixture-*.jpg' | sort)

if [[ "${#media_files[@]}" -ne "$count" ]]; then
  echo "Expected $count generated JPEG assets but found ${#media_files[@]} in $output." >&2
  exit 70
fi

if [[ "$generate_only" -eq 1 ]]; then
  echo "Generated ${#media_files[@]} JPEG assets in $output"
  exit 0
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required to import media into Simulator." >&2
  exit 69
fi

import_files=("${media_files[@]:$start_index:$((end_index - start_index + 1))}")

echo "Importing ${#import_files[@]} JPEG assets into simulator '$simulator' from sorted index ${start_index} to ${end_index}..."
batch=()
imported_count=0
batch_number=1
for media_file in "${import_files[@]}"; do
  batch+=("$media_file")

  if [[ "${#batch[@]}" -ge "$batch_size" ]]; then
    echo "Importing batch ${batch_number}: $((imported_count + 1))-$((imported_count + ${#batch[@]})) of ${#import_files[@]}"
    xcrun simctl addmedia "$simulator" "${batch[@]}"
    imported_count=$((imported_count + ${#batch[@]}))
    batch_number=$((batch_number + 1))
    batch=()
  fi
done

if [[ "${#batch[@]}" -gt 0 ]]; then
  echo "Importing batch ${batch_number}: $((imported_count + 1))-$((imported_count + ${#batch[@]})) of ${#import_files[@]}"
  xcrun simctl addmedia "$simulator" "${batch[@]}"
  imported_count=$((imported_count + ${#batch[@]}))
fi

echo "Imported ${imported_count} assets from $output"
