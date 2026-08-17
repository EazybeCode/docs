#!/usr/bin/env bash
# Copies the 17 AI-agent screenshots from a SOURCE folder into the docs images
# folder with the exact filenames the MDX pages expect.
#
# Usage:  bash scripts/place-agent-images.sh "/path/to/folder/with/screenshots"
#
# The source folder must contain exactly the 17 screenshots, and they must sort
# (by filename) in the same order as the NAMES list below. If your screenshots
# are named like "Screenshot 2026-... at ....png", they already sort by capture
# time, which matches the step order.

set -euo pipefail

SRC="${1:-}"
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "ERROR: pass the folder that holds your 17 screenshots."
  echo 'Example: bash scripts/place-agent-images.sh "$HOME/Desktop"'
  exit 1
fi

DEST="$(cd "$(dirname "$0")/.." && pwd)/images/creating-ai-agent"
mkdir -p "$DEST"

NAMES=(
  ai-agents-empty.png
  describe-agent.png
  bea-setup.png
  question-primary-goal.png
  question-nudges.png
  funnel.png
  workspace-playground.png
  add-tool.png
  conversations.png
  prompt.png
  learnings.png
  settings.png
  billing.png
  analytics.png
  kb-empty.png
  kb-add-source.png
  kb-indexing.png
)

# Collect image files from SRC, sorted by name.
shopt -s nullglob
FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(find "$SRC" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)

echo "Found ${#FILES[@]} image(s) in: $SRC"
if [[ ${#FILES[@]} -ne ${#NAMES[@]} ]]; then
  echo "WARNING: expected ${#NAMES[@]} images but found ${#FILES[@]}."
  echo "It will map as many as it can, in sorted order. Check the result below."
fi

count=0
for i in "${!NAMES[@]}"; do
  [[ $i -lt ${#FILES[@]} ]] || break
  cp "${FILES[$i]}" "$DEST/${NAMES[$i]}"
  echo "  $(basename "${FILES[$i]}")  ->  ${NAMES[$i]}"
  count=$((count+1))
done

echo "Placed $count image(s) into $DEST"
