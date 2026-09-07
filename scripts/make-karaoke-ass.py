#!/usr/bin/env python3
"""Generate a karaoke ASS subtitle file from a slides TSV + the build's VTT sidecar.

Each narration line becomes one dialogue whose words flip from white (unspoken)
to brand purple (spoken). Word timings are estimated proportionally to word
length within the slide's known audio duration - TTS speech is even-paced, so
this lands within a fraction of a second per word.

Usage: make-karaoke-ass.py <slides.tsv> <walkthrough.vtt> <out.ass> [wrap]
Then burn with: ffmpeg -i in.mp4 -vf "ass=out.ass" -c:a copy out.mp4
"""
import re
import sys
import textwrap

HEADER = """[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Karaoke,Arial,42,&H00F8AFB9,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,78,100,0,0,1,3,1,2,12,12,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""


def tsec(ts):
    h, m, s = ts.split(":")
    return int(h) * 3600 + int(m) * 60 + float(s)


def ass_ts(t):
    cs = int(round(t * 100))
    return f"{cs // 360000}:{cs // 6000 % 60:02d}:{cs // 100 % 60:02d}.{cs % 100:02d}"


def main():
    tsv, vtt_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
    wrap = int(sys.argv[4]) if len(sys.argv) > 4 else 135
    rows = [l.split("\t") for l in open(tsv) if l.strip() and not l.startswith("#")]
    cues = re.findall(r"(\d+:\d+:[\d.]+) --> (\d+:\d+:[\d.]+)\n(.+)", open(vtt_path).read())
    assert len(cues) == len(rows), f"cue/row mismatch: {len(cues)} vs {len(rows)}"

    lines = [HEADER]
    for (cs_, ce_, _), row in zip(cues, rows):
        narr = row[3].strip()
        start, end = tsec(cs_), tsec(ce_)
        da = end - start - 0.1  # speech duration inside the cue (cue holds past speech end)
        words = narr.split()
        weights = [len(w) + 1 for w in words]
        total = sum(weights)
        durs_cs = [int(round(da * 100 * w / total)) for w in weights]
        durs_cs[-1] += int(round(da * 100)) - sum(durs_cs)  # absorb rounding drift

        wrapped = textwrap.wrap(narr, wrap)
        counts = [len(l.split()) for l in wrapped]
        parts, idx = [], 0
        for li, n in enumerate(counts):
            if li:
                parts.append("\\N")
            for w, d in zip(words[idx:idx + n], durs_cs[idx:idx + n]):
                parts.append("{\\k%d}%s " % (d, w))
            idx += n
        lines.append(f"Dialogue: 0,{ass_ts(start)},{ass_ts(end)},Karaoke,,0,0,0,,{''.join(parts).rstrip()}")
    open(out, "w").write("\n".join(lines) + "\n")
    print(f"wrote {out} ({len(rows)} dialogues)")


if __name__ == "__main__":
    main()
