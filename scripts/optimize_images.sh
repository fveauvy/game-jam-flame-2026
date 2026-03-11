#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/optimize_images.sh <source_dir> <output_dir>

Mac + Homebrew only.
Requires: pngquant, oxipng, jpegoptim

Example:
  scripts/optimize_images.sh assets/images build/optimized-assets/images
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew required" >&2
  exit 1
fi

missing_tools=()
for tool in pngquant oxipng jpegoptim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing_tools+=("$tool")
  fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
  echo "Missing tools: ${missing_tools[*]}" >&2
  echo "Install with: brew install ${missing_tools[*]}" >&2
  exit 1
fi

source_dir="${1%/}"
output_dir="${2%/}"

if [[ ! -d "$source_dir" ]]; then
  echo "Source dir not found: $source_dir" >&2
  exit 1
fi

mkdir -p "$output_dir"
rsync -a --delete "$source_dir/" "$output_dir/"

echo "Optimizing PNG files..."
while IFS= read -r -d '' png_file; do
  temp_file="${png_file}.tmp"
  if pngquant --strip --skip-if-larger --quality=75-98 --speed 1 --force --output "$temp_file" -- "$png_file" >/dev/null 2>&1; then
    mv "$temp_file" "$png_file"
  elif [[ -f "$temp_file" ]]; then
    rm -f "$temp_file"
  fi
  oxipng -o 4 --strip safe --quiet "$png_file" >/dev/null 2>&1 || true
done < <(find "$output_dir" -type f \( -iname '*.png' \) -print0)

echo "Optimizing JPEG files..."
while IFS= read -r -d '' jpg_file; do
  jpegoptim --strip-all --max=90 --quiet "$jpg_file" >/dev/null 2>&1 || true
done < <(find "$output_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0)

find "$output_dir" -type f \( -name '.DS_Store' -o -name '*~' \) -delete

echo "Done: $output_dir"
