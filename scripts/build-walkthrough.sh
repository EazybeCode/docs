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
#   --fit <pad|cover>        pad = letterbox to 16:9 (default); cover = fill frame, no bars (crops edges)
#   --fade-color <color>     color slides fade from/to (default: black; try white for light UIs)
#   --burn-narration         burn the narration text as on-screen subtitles (replaces the short caption)
#   --no-title               omit the purple title bar (no step name burned in at the top)
#   --sub-color <color>      subtitle text color (default: 0xE6E8EF light gray; try black)
#   --no-sub-box             drop the dark box behind the subtitle text
#   --sub-band <px>          reserve a dedicated strip below the screenshot for subtitles
#                            (nothing overlaps the UI; try 150). Overrides --fit for layout.
#   --sub-band-bg <color>    band background color (default: 0x0f1117 dark; try white)
#   --sub-pos <bottom|top>   where the caption sits when overlaid (default: bottom)
#   --sub-box-color <color>  caption box color (default: 0x0f1117@0.82; try 0x6C5CE7 brand pill)
#   --sub-style <box|outline|genuine|none> box = dark box (default); outline = movie-style;
#                            none = no burned caption (e.g. when adding karaoke subs after)
#                            white text with dark outline; genuine = broadcast-standard white
#                            text on semi-transparent black backing, max ~2 lines
#   --out <path>             output file (default: <images-dir>/<slug>-walkthrough[-narrated].mp4)
#
# Narrated builds also emit a WebVTT sidecar (<out>.vtt) and cache TTS audio in
# <images-dir>/.tts-cache so re-running with unchanged narration makes no API calls.
#
# Requires ffmpeg: run  scripts/fetch-ffmpeg.sh  first (or have ffmpeg on PATH).
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
IMGDIR="${1:-}"; shift || true
[ -n "$IMGDIR" ] && [ -d "$IMGDIR" ] || { echo "ERROR: pass the images dir, e.g. images/creating-ai-agent"; exit 1; }
IMGDIR="$(cd "$IMGDIR" && pwd)"
TSV="$IMGDIR/slides.tsv"
[ -f "$TSV" ] || { echo "ERROR: $TSV not found (see authoring/walkthrough-video-prompt.md §3)"; exit 1; }

NARRATE=0; VOICE="nova"; KEYFILE=""; MODEL="tts-1"; SECS=5; ZOOM="1.0"; OUT=""; FIT="pad"; FADECOLOR="black"; BURNNARR=0; NOTITLE=0; SUBCOLOR="0xE6E8EF"; SUBBOX=1; SUBBAND=0; BANDBG="0x0f1117"; SUBPOS="bottom"; SUBBOXCOLOR="0x0f1117@0.82"; SUBSTYLEPRESET="box"
while [ $# -gt 0 ]; do case "$1" in
  --narrate) NARRATE=1;;
  --voice) VOICE="$2"; shift;;
  --key-file) KEYFILE="$2"; shift;;
  --model) MODEL="$2"; shift;;
  --secs) SECS="$2"; shift;;
  --zoom) ZOOM="$2"; shift;;
  --fit) FIT="$2"; shift;;
  --fade-color) FADECOLOR="$2"; shift;;
  --burn-narration) BURNNARR=1;;
  --no-title) NOTITLE=1;;
  --sub-color) SUBCOLOR="$2"; shift;;
  --no-sub-box) SUBBOX=0;;
  --sub-band) SUBBAND="$2"; shift;;
  --sub-band-bg) BANDBG="$2"; shift;;
  --sub-pos) SUBPOS="$2"; shift;;
  --sub-box-color) SUBBOXCOLOR="$2"; shift;;
  --sub-style) SUBSTYLEPRESET="$2"; shift;;
  --out) OUT="$2"; shift;;
  *) echo "unknown option: $1"; exit 1;;
esac; shift; done
case "$FIT" in pad|cover) ;; *) echo "ERROR: --fit must be pad or cover"; exit 1;; esac

# locate ffmpeg
FFMPEG="$(command -v ffmpeg || true)"; [ -z "$FFMPEG" ] && [ -x "$DIR/bin/ffmpeg" ] && FFMPEG="$DIR/bin/ffmpeg"
[ -n "$FFMPEG" ] || { echo "ERROR: ffmpeg not found. Run: bash scripts/fetch-ffmpeg.sh"; exit 1; }

SLUG="$(basename "$IMGDIR")"
[ -z "$OUT" ] && { OUT="$IMGDIR/${SLUG}-walkthrough$([ $NARRATE = 1 ] && echo -narrated).mp4"; }
FONT=""; for f in /System/Library/Fonts/Supplemental/Arial.ttf /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /Library/Fonts/Arial.ttf; do [ -f "$f" ] && FONT="$f" && break; done
[ -n "$FONT" ] || { echo "ERROR: no usable .ttf font found"; exit 1; }

W=1920; H=1080; FPS=30
if [ "$FIT" = "cover" ]; then
  PREP="scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H},setsar=1"
else
  PREP="scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=0x0f1117,setsar=1"
fi
# bottom text: burned narration sits centered; the short caption sits bottom-left
if [ $BURNNARR = 1 ]; then SUBX="(w-tw)/2"; SUBY="h-th-56"; else SUBX="56"; SUBY="${H}-74"; fi
SUBSTYLE=":box=1:boxcolor=${SUBBOXCOLOR}:boxborderw=16"; [ $SUBBOX = 0 ] && SUBSTYLE=""
[ "$SUBPOS" = "top" ] && { SUBX="(w-tw)/2"; SUBY="36"; }
SUBSIZE=30; WRAP=64
if [ "$SUBSTYLEPRESET" = "outline" ]; then
  # movie-style subtitles: white text, dark outline + soft shadow, no box
  SUBSTYLE=":borderw=3:bordercolor=0x000000@0.9:shadowx=2:shadowy=2:shadowcolor=0x000000@0.45"
  SUBCOLOR="white"; SUBSIZE=28; WRAP=84
elif [ "$SUBSTYLEPRESET" = "genuine" ]; then
  # broadcast-standard captions: white text on semi-transparent black, wraps to ~2 lines
  SUBSTYLE=":box=1:boxcolor=0x000000@0.6:boxborderw=12"
  SUBCOLOR="white"; SUBSIZE=24; WRAP=135
fi
if [ "$SUBBAND" -gt 0 ]; then
  # band mode: screenshot fits above, subtitles live in their own strip — nothing overlaps the UI
  CH=$((H-SUBBAND))
  PREP="scale=${W}:${CH}:force_original_aspect_ratio=decrease,pad=${W}:${CH}:(ow-iw)/2:(oh-ih)/2:color=white,pad=${W}:${H}:0:0:color=${BANDBG},setsar=1"
  SUBX="(w-tw)/2"; SUBY="${CH}+(${SUBBAND}-th)/2"; SUBSTYLE=""; SUBSIZE=26; WRAP=96
fi
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
KEY=""; [ $NARRATE = 1 ] && { [ -n "$KEYFILE" ] && [ -f "$KEYFILE" ] || { echo "ERROR: --narrate needs --key-file <path>"; exit 1; }; KEY="$(cat "$KEYFILE")"; }

dur_of(){ local o; o="$("$FFMPEG" -nostdin -i "$1" 2>&1 || true)"; printf '%s\n' "$o" | awk -F'[:,]' '/Duration/{print $2*3600+$3*60+$4; exit}'; }
ts_of(){ python3 -c "t=float('$1');print('%02d:%02d:%06.3f'%(t//3600,(t%3600)//60,t%60))"; }

# narrated builds also emit a WebVTT subtitle sidecar (<out>.vtt) with one cue per slide
VTT="${OUT%.mp4}.vtt"; T=0
[ $NARRATE = 1 ] && printf 'WEBVTT\n' > "$VTT"

i=0
while IFS=$'\t' read -r img title sub narr || [ -n "${img:-}" ]; do
  [ -z "${img:-}" ] && continue
  case "$img" in \#*) continue;; esac
  for one in ${img//|/ }; do [ -f "$IMGDIR/$one" ] || { echo "ERROR: image not found: $IMGDIR/$one"; exit 1; }; done
  tf="$WORK/t_$i.txt"; sf="$WORK/s_$i.txt"; clip="$WORK/clip_$(printf %03d $i).mp4"
  printf '%s' "${title:-}" > "$tf"
  if [ $BURNNARR = 1 ] && [ -n "${narr:-}" ]; then
    python3 -c 'import sys,textwrap;print("\n".join(textwrap.wrap(sys.argv[1], int(sys.argv[2]))))' "$narr" "$WRAP" > "$sf"
  else
    printf '%s' "${sub:-}" > "$sf"
  fi
  TITLEF="drawbox=x=0:y=0:w=${W}:h=92:color=0x6C5CE7@1:t=fill,drawtext=fontfile=${FONT}:textfile=${tf}:x=56:y=24:fontsize=44:fontcolor=white,"
  [ $NOTITLE = 1 ] && TITLEF=""
  SUBF="drawtext=fontfile=${FONT}:textfile=${sf}:x=${SUBX}:y=${SUBY}:fontsize=${SUBSIZE}:line_spacing=10:fontcolor=${SUBCOLOR}${SUBSTYLE},"
  [ "$SUBSTYLEPRESET" = "none" ] && SUBF=""
  zexpr="1+(${ZOOM}-1)*on/($((SECS*FPS))-1)"   # recomputed per-slide below when narrated

  if [ $NARRATE = 1 ]; then
    [ -n "${narr:-}" ] || { echo "ERROR: row $i has no narration (needed with --narrate)"; exit 1; }
    CDIR="$IMGDIR/.tts-cache"; mkdir -p "$CDIR"
    hash=$(python3 -c 'import hashlib,sys;print(hashlib.md5(sys.argv[1].encode()).hexdigest())' "$MODEL|$VOICE|$narr")
    a="$CDIR/$hash.mp3"
    if [ ! -s "$a" ]; then
      code=$(curl -s -o "$a" -w "%{http_code}" https://api.openai.com/v1/audio/speech \
        -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
        -d "$(python3 -c 'import json,sys;print(json.dumps({"model":sys.argv[1],"voice":sys.argv[2],"input":sys.argv[3]}))' "$MODEL" "$VOICE" "$narr")")
      [ "$code" = "200" ] && [ -s "$a" ] || { rm -f "$a"; echo "TTS failed row $i (http=$code)"; exit 1; }
    else
      echo "  [$i] tts cache hit ($hash)"
    fi
    da=$(dur_of "$a"); sd=$(echo "$da + 1.0" | bc); fo=$(echo "$sd - 0.4" | bc)
    D=$(python3 -c "print(int(round($sd*$FPS)))"); zexpr="1+(${ZOOM}-1)*on/(${D}-1)"
    echo "  [$i] ${img}  audio=${da}s  slide=${sd}s"
    printf '\n%s --> %s\n%s\n' "$(ts_of "$(echo "$T + 0.4" | bc)")" "$(ts_of "$(echo "$T + $sd - 0.1" | bc)")" "$narr" >> "$VTT"
    T=$(echo "$T + $sd" | bc)
    IFS='|' read -r -a IMGARR <<< "$img"
    N=${#IMGARR[@]}
    if [ "$N" -gt 1 ]; then
      # multi-image slide: the narration plays once while the images advance with hard cuts
      : > "$WORK/seg_$i.txt"
      for k in $(seq 0 $((N-1))); do
        if [ $k -eq $((N-1)) ]; then segd=$(python3 -c "print(round($sd - $k*($sd/$N), 3))"); else segd=$(python3 -c "print(round($sd/$N, 3))"); fi
        Dk=$(python3 -c "print(max(2, int(round($segd*$FPS))))")
        zk="1+(${ZOOM}-1)*on/(${Dk}-1)"
        FADEF=""
        [ $k -eq 0 ] && FADEF="fade=t=in:st=0:d=0.4:color=${FADECOLOR},"
        [ $k -eq $((N-1)) ] && FADEF="${FADEF}fade=t=out:st=$(python3 -c "print(round($segd-0.4, 3))"):d=0.4:color=${FADECOLOR},"
        segclip="$WORK/seg_${i}_${k}.mp4"
        "$FFMPEG" -nostdin -loglevel error -y -loop 1 -i "$IMGDIR/${IMGARR[$k]}" -filter_complex "\
[0:v]${PREP}[b];\
[b]zoompan=z='${zk}':x='0.5*iw-(iw/zoom/2)':y='0.5*ih-(ih/zoom/2)':d=${Dk}:s=${W}x${H}:fps=${FPS}[zm];\
[zm]${TITLEF}${SUBF}${FADEF}format=yuv420p[v]" \
          -map "[v]" -t "$segd" -r $FPS -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p "$segclip"
        echo "file '$segclip'" >> "$WORK/seg_$i.txt"
      done
      "$FFMPEG" -nostdin -loglevel error -y -f concat -safe 0 -i "$WORK/seg_$i.txt" -i "$a" \
        -filter_complex "[1:a]adelay=400|400,apad,afade=t=out:st=${fo}:d=0.4[a]" \
        -map 0:v -map "[a]" -t "$sd" -c:v copy -c:a aac -b:a 128k -ar 44100 "$clip"
    else
    "$FFMPEG" -nostdin -loglevel error -y -loop 1 -i "$IMGDIR/$img" -i "$a" -filter_complex "\
[0:v]${PREP}[b];\
[b]zoompan=z='${zexpr}':x='0.5*iw-(iw/zoom/2)':y='0.5*ih-(ih/zoom/2)':d=${D}:s=${W}x${H}:fps=${FPS}[zm];\
[zm]${TITLEF}${SUBF}fade=t=in:st=0:d=0.4:color=${FADECOLOR},fade=t=out:st=${fo}:d=0.4:color=${FADECOLOR},format=yuv420p[v];\
[1:a]adelay=400|400,apad,afade=t=out:st=${fo}:d=0.4[a]" \
      -map "[v]" -map "[a]" -t "$sd" -r $FPS -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
      -c:a aac -b:a 128k -ar 44100 "$clip"
    fi
  else
    sd=$SECS; fo=$(echo "$sd - 0.45" | bc); D=$((SECS*FPS)); zexpr="1+(${ZOOM}-1)*on/(${D}-1)"
    echo "  [$i] ${img}  (${sd}s, silent)"
    "$FFMPEG" -nostdin -loglevel error -y -i "$IMGDIR/$img" -filter_complex "\
[0:v]${PREP}[b];\
[b]zoompan=z='${zexpr}':x='0.5*iw-(iw/zoom/2)':y='0.5*ih-(ih/zoom/2)':d=${D}:s=${W}x${H}:fps=${FPS}[zm];\
[zm]${TITLEF}${SUBF}fade=t=in:st=0:d=0.45:color=${FADECOLOR},fade=t=out:st=${fo}:d=0.45:color=${FADECOLOR},format=yuv420p[v]" \
      -map "[v]" -r $FPS -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p "$clip"
  fi
  i=$((i+1))
done < "$TSV"

[ $i -gt 0 ] || { echo "ERROR: no slides read from $TSV"; exit 1; }
: > "$WORK/list.txt"; for c in "$WORK"/clip_*.mp4; do echo "file '$c'" >> "$WORK/list.txt"; done
"$FFMPEG" -nostdin -loglevel error -y -f concat -safe 0 -i "$WORK/list.txt" -c copy "$OUT"
echo "DONE ($i slides) -> $OUT"
"$FFMPEG" -hide_banner -i "$OUT" 2>&1 | grep -E "Duration|Stream #0" || true
