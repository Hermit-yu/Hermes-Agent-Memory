#!/bin/bash
# scripts/ffmpeg-compose.sh
# Assemble frames/frame_%04d.jpg into output.mp4 at 24fps H.264

INPUT_DIR="${1:-frames}"
OUTPUT="${2:-output.mp4}"
FPS="${3:-24}"

mkdir -p "$(dirname "$OUTPUT")"

ffmpeg -y \
  -framerate "$FPS" \
  -i "${INPUT_DIR}/frame_%04d.jpg" \
  -c:v libx264 \
  -pix_fmt yuv420p \
  -crf 18 \
  -preset slow \
  -r "$FPS" \
  "$OUTPUT"

echo "Composed $OUTPUT from $INPUT_DIR at ${FPS}fps"
