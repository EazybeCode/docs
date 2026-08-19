#!/usr/bin/env bash
# Downloads a self-contained static ffmpeg into scripts/bin/ffmpeg (no admin / brew).
# Used by build-walkthrough.sh. Safe to re-run.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/bin"; mkdir -p "$BIN"
OUT="$BIN/ffmpeg"

if [ -x "$OUT" ]; then echo "ffmpeg already present: $OUT ($("$OUT" -version 2>/dev/null | head -1))"; exit 0; fi

os="$(uname -s)"; arch="$(uname -m)"
case "$os/$arch" in
  Darwin/arm64) url="https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1/ffmpeg-darwin-arm64" ;;
  Darwin/x86_64) url="https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1/ffmpeg-darwin-x64" ;;
  Linux/x86_64) url="https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1/ffmpeg-linux-x64" ;;
  Linux/aarch64) url="https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1/ffmpeg-linux-arm64" ;;
  *) echo "Unsupported platform $os/$arch. Install ffmpeg manually and ensure it's on PATH."; exit 1 ;;
esac

echo "Downloading static ffmpeg for $os/$arch ..."
curl -sL -o "$OUT" "$url"
chmod +x "$OUT"
xattr -d com.apple.quarantine "$OUT" 2>/dev/null || true
echo "OK: $OUT"
"$OUT" -version 2>/dev/null | head -1
