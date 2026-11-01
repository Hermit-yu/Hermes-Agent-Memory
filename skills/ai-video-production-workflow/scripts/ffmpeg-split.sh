#!/bin/bash
# scripts/ffmpeg-split.sh
# Split reference video into preview frames (1 frame per 10 seconds)

INPUT="${1:-reference.mp4}"
OUTPUT_DIR="${2:-frames}"
INTERVAL="${3:-10}"

mkdir -p "$OUTPUT_DIR"

ffmpeg -y \
  -i "$INPUT" \
  -vf "fps=1/$INTERVAL,scale=1920:1080" \
  -q:v 2 \
  "${OUTPUT_DIR}/preview_%04d.jpg"

echo "Split $INPUT into frames every ${INTERVAL}s in $OUTPUT_DIR"
