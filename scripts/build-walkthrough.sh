#!/usr/bin/env bash
# Build a captioned walkthrough video from a feature's screenshots + slides.tsv.
#
# Usage:
#   scripts/build-walkthrough.sh images/<feature-slug> [options]
#
# Reads  <images-dir>/slides.tsv  (tab-separated, one row per screen):
#   image <TAB> title <TAB> subtitle <TAB> narration
#   ( '#' comments and blank lines ignored; narration optional unless --narrate )
#
# Options:
#   --narrate                generate AI voiceover (needs --key-file)
#   --voice <name>           TTS voice (default: nova)   [openai: nova|onyx|alloy|echo|fable|shimmer]
#   --key-file <path>        file containing the OpenAI API key (e.g. ~/.openai_key)
#   --model <name>           TTS model (default: tts-1)
#   --secs <n>               seconds per slide in SILENT mode (default: 5)
#   --zoom <z>               end zoom factor (default: 1.0 = no zoom; try 1.10 for subtle)
#   --out <path>             output file (default: <images-dir>/<slug>-walkthrough[-narrated].mp4)
#
# Requires ffmpeg: run  scripts/fetch-ffmpeg.sh  first (or have ffmpeg on PATH).
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
IMGDIR="${1:-}"; shift || true
[ -n "$IMGDIR" ] && [ -d "$IMGDIR" ] || { echo "ERROR: pass the images dir, e.g. images/creating-ai-agent"; exit 1; }
IMGDIR="$(cd "$IMGDIR" && pwd)"
TSV="$IMGDIR/slides.tsv"
[ -f "$TSV" ] || { echo "ERROR: $TSV not found (see authoring/walkthrough-video-prompt.md §3)"; exit 1; }

NARRATE=0; VOICE="nova"; KEYFILE=""; MODEL="tts-1"; SECS=5; ZOOM="1.0"; OUT=""
while [ $# -gt 0 ]; do case "$1" in
  --narrate) NARRATE=1;;
  --voice) VOICE="$2"; shift;;
  --key-file) KEYFILE="$2"; shift;;
  --model) MODEL="$2"; shift;;
  --secs) SECS="$2"; shift;;
  --zoom) ZOOM="$2"; shift;;
  --out) OUT="$2"; shift;;
  *) echo "unknown option: $1"; exit 1;;
esac; shift; done

# locate ffmpeg
FFMPEG="$(command -v ffmpeg || true)"; [ -z "$FFMPEG" ] && [ -x "$DIR/bin/ffmpeg" ] && FFMPEG="$DIR/bin/ffmpeg"
[ -n "$FFMPEG" ] || { echo "ERROR: ffmpeg not found. Run: bash scripts/fetch-ffmpeg.sh"; exit 1; }

SLUG="$(basename "$IMGDIR")"
[ -z "$OUT" ] && { OUT="$IMGDIR/${SLUG}-walkthrough$([ $NARRATE = 1 ] && echo -narrated).mp4"; }
FONT=""; for f in /System/Library/Fonts/Supplemental/Arial.ttf /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /Library/Fonts/Arial.ttf; do [ -f "$f" ] && FONT="$f" && break; done
[ -n "$FONT" ] || { echo "ERROR: no usable .ttf font found"; exit 1; }

W=1920; H=1080; FPS=30
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
KEY=""; [ $NARRATE = 1 ] && { [ -n "$KEYFILE" ] && [ -f "$KEYFILE" ] || { echo "ERROR: --narrate needs --key-file <path>"; exit 1; }; KEY="$(cat "$KEYFILE")"; }

dur_of(){ local o; o="$("$FFMPEG" -nostdin -i "$1" 2>&1 || true)"; printf '%s\n' "$o" | awk -F'[:,]' '/Duration/{print $2*3600+$3*60+$4; exit}'; }

i=0
while IFS=$'\t' read -r img title sub narr || [ -n "${img:-}" ]; do
  [ -z "${img:-}" ] && continue
  case "$img" in \#*) continue;; esac
  [ -f "$IMGDIR/$img" ] || { echo "ERROR: image not found: $IMGDIR/$img"; exit 1; }
  tf="$WORK/t_$i.txt"; sf="$WORK/s_$i.txt"; clip="$WORK/clip_$(printf %03d $i).mp4"
  printf '%s' "${title:-}" > "$tf"; printf '%s' "${sub:-}" > "$sf"
  zexpr="1+(${ZOOM}-1)*on/($((SECS*FPS))-1)"   # recomputed per-slide below when narrated

  if [ $NARRATE = 1 ]; then
    [ -n "${narr:-}" ] || { echo "ERROR: row $i has no narration (needed with --narrate)"; exit 1; }
    a="$WORK/a_$i.mp3"
    code=$(curl -s -o "$a" -w "%{http_code}" https://api.openai.com/v1/audio/speech \
      -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
      -d "$(python3 -c 'import json,sys;print(json.dumps({"model":sys.argv[1],"voice":sys.argv[2],"input":sys.argv[3]}))' "$MODEL" "$VOICE" "$narr")")
    [ "$code" = "200" ] && [ -s "$a" ] || { echo "TTS failed row $i (http=$code): $(head -c 200 "$a")"; exit 1; }
    da=$(dur_of "$a"); sd=$(echo "$da + 1.0" | bc); fo=$(echo "$sd - 0.4" | bc)
    D=$(python3 -c "print(int(round($sd*$FPS)))"); zexpr="1+(${ZOOM}-1)*on/(${D}-1)"
    echo "  [$i] ${img}  audio=${da}s  slide=${sd}s"
    "$FFMPEG" -nostdin -loglevel error -y -loop 1 -i "$IMGDIR/$img" -i "$a" -filter_complex "\
[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=0x0f1117,setsar=1[b];\
[b]zoompan=z='${zexpr}':x='0.5*iw-(iw/zoom/2)':y='0.5*ih-(ih/zoom/2)':d=${D}:s=${W}x${H}:fps=${FPS}[zm];\
[zm]drawbox=x=0:y=0:w=${W}:h=92:color=0x6C5CE7@1:t=fill[bar];\
[bar]drawtext=fontfile=${FONT}:textfile=${tf}:x=56:y=24:fontsize=44:fontcolor=white[t1];\
[t1]drawtext=fontfile=${FONT}:textfile=${sf}:x=56:y=${H}-74:fontsize=30:fontcolor=0xE6E8EF:box=1:boxcolor=0x0f1117@0.82:boxborderw=16[t2];\
[t2]fade=t=in:st=0:d=0.4,fade=t=out:st=${fo}:d=0.4,format=yuv420p[v];\
[1:a]adelay=400|400,apad,afade=t=out:st=${fo}:d=0.4[a]" \
      -map "[v]" -map "[a]" -t "$sd" -r $FPS -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
      -c:a aac -b:a 128k -ar 44100 "$clip"
  else
    sd=$SECS; fo=$(echo "$sd - 0.45" | bc); D=$((SECS*FPS)); zexpr="1+(${ZOOM}-1)*on/(${D}-1)"
    echo "  [$i] ${img}  (${sd}s, silent)"
    "$FFMPEG" -nostdin -loglevel error -y -i "$IMGDIR/$img" -filter_complex "\
[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=0x0f1117,setsar=1[b];\
[b]zoompan=z='${zexpr}':x='0.5*iw-(iw/zoom/2)':y='0.5*ih-(ih/zoom/2)':d=${D}:s=${W}x${H}:fps=${FPS}[zm];\
[zm]drawbox=x=0:y=0:w=${W}:h=92:color=0x6C5CE7@1:t=fill[bar];\
[bar]drawtext=fontfile=${FONT}:textfile=${tf}:x=56:y=24:fontsize=44:fontcolor=white[t1];\
[t1]drawtext=fontfile=${FONT}:textfile=${sf}:x=56:y=${H}-74:fontsize=30:fontcolor=0xE6E8EF:box=1:boxcolor=0x0f1117@0.82:boxborderw=16[t2];\
[t2]fade=t=in:st=0:d=0.45,fade=t=out:st=${fo}:d=0.45,format=yuv420p[v]" \
      -map "[v]" -r $FPS -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p "$clip"
  fi
  i=$((i+1))
done < "$TSV"

[ $i -gt 0 ] || { echo "ERROR: no slides read from $TSV"; exit 1; }
: > "$WORK/list.txt"; for c in "$WORK"/clip_*.mp4; do echo "file '$c'" >> "$WORK/list.txt"; done
"$FFMPEG" -nostdin -loglevel error -y -f concat -safe 0 -i "$WORK/list.txt" -c copy "$OUT"
echo "DONE ($i slides) -> $OUT"
"$FFMPEG" -hide_banner -i "$OUT" 2>&1 | grep -E "Duration|Stream #0" || true
