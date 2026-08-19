# Walkthrough Video — Prompt & Process

> **What this is:** a reusable process (+ scripts) for turning a feature's help-doc screenshots into a short **narrated or silent walkthrough video**, in the same house style as the help docs. Any PM can run it with no video-editing skills. Kept separate from the doc-writing playbook on purpose.

**Reference example:** the AI Agent walkthrough was made this way — 17 screenshots + a `slides.tsv` → a silent `…-walkthrough.mp4` and a narrated `…-walkthrough-narrated.mp4`, all in one command.

---

## 1. What the video is (and isn't)

- A **captioned slideshow** of the same screenshots used in the help doc: each screen held for a few seconds, fade between screens, a title bar (step name) and a one-line caption burned in. Optional **AI voiceover** reads a short line per screen.
- Built **locally with `ffmpeg`** — free, no cloud, no editing app. The only paid part is optional voiceover (a text-to-speech API, ~cents per video).
- **Not** AI-generated motion footage. We deliberately keep it a clean slideshow — it's for docs, and it must exactly match the product.
- **Zoom is OFF by default** (static slides). A subtle zoom is available but off unless you ask for it — full-screen static reads calmest.

---

## 2. One-time setup: get ffmpeg (no admin needed)

```
bash scripts/fetch-ffmpeg.sh
```

Downloads a self-contained static `ffmpeg` into `scripts/bin/ffmpeg`. No Homebrew, no sudo. The build script finds it automatically.

---

## 3. Author the slide list: `slides.tsv`

In the feature's image folder, create `slides.tsv` — one row per screen, **tab-separated**, columns:

```
image<TAB>title<TAB>subtitle<TAB>narration
```

- `image` — filename in the same folder (e.g. `kb-add-source.png`)
- `title` — the burned-in step name (e.g. `16. Add a source`)
- `subtitle` — one-line caption (e.g. `Website, document, or text`)
- `narration` — the spoken line (leave empty for silent-only; required for voiceover)

Lines starting with `#` and blank lines are ignored. Example rows:

```
# image	title	subtitle	narration
kb-empty.png	15. Knowledge base	What your agent answers from	Finally, the knowledge base — what your agent answers from. Let's add a source.
kb-add-source.png	16. Add a source	Website, document, or text	Add a website, upload a document, or paste text, then click Start reading.
```

### Prompt to draft the narration (copy-paste to your AI assistant)

```
I'm making a help walkthrough video for <feature>. Below is my ordered list of
screenshots and what each shows. Write ONE narration line per screenshot:
- spoken, natural, ~1 sentence, 8–18 words
- calm second person ("you"), no hype, no "simply/just"
- quote the real UI label the user should look for
- the LAST line should wrap up ("…and that's it — <outcome>.")
Output as tab-separated rows:  image<TAB>title<TAB>subtitle<TAB>narration

SCREENSHOTS:
1. <name>.png — <what's on screen>
2. ...
```

<b>Pronunciation:</b> TTS reads names literally. If a brand/product name is mispronounced, spell it phonetically in the `narration` column only (the on-screen `title`/`subtitle` keep the real spelling). For example, write <code>Bee</code> so the voice says "Bee" for the assistant <b>Bea</b>.

---

## 4. Build the video

Silent + captions (no key, free):
```
bash scripts/build-walkthrough.sh images/<feature-slug>
```

With AI voiceover (OpenAI TTS; needs a key in a file — see §5):
```
bash scripts/build-walkthrough.sh images/<feature-slug> --narrate --voice nova --key-file ~/.openai_key
```

Output lands in the same folder: `images/<feature-slug>/<feature-slug>-walkthrough.mp4` (silent) or `…-walkthrough-narrated.mp4`.

Useful flags: `--secs 5` (seconds per silent slide), `--zoom 1.10` (enable subtle zoom; default `1.0` = off).

---

## 5. Voiceover: which API, cost, and key safety

Voiceover needs a **text-to-speech (TTS)** provider. Note: an **OpenRouter** key does **not** work — it's a text-LLM gateway with no speech endpoint.

| Provider | Key format / source | Notes |
|---|---|---|
| **OpenAI** `tts-1` | `sk-…` from platform.openai.com | Default in the script. ~$0.015 / 1,000 chars → a typical video ≈ **$0.03**. Voices: `nova` (warm), `onyx` (deep), `alloy` (neutral). |
| ElevenLabs | ElevenLabs key | Most natural; adapt the script's TTS call. |
| Google Gemini TTS | `AIza…` from aistudio.google.com/app/apikey | Google option; note AI-Studio keys start with `AIza`, **not** `AQ.` (that's an OAuth token). |

**Key safety (important):**
- **Never paste an API key into chat / commit it / put it in a doc.** Put it in a file outside the repo:
  ```
  umask 077; printf '%s\n' "sk-…yourkey" > ~/.openai_key
  ```
  Pass it with `--key-file ~/.openai_key`. The script reads it from there.
- If a key ever gets exposed, **revoke it** in the provider dashboard and make a new one.
- Confirm the small spend is expected before running (`--narrate` makes one TTS call per row).

---

## 6. Embed the video in the help doc (optional)

Mintlify renders HTML5 video. At the top of the relevant `.mdx` page:

```mdx
<video controls className="w-full aspect-video rounded-xl" src="/images/<feature-slug>/<feature-slug>-walkthrough-narrated.mp4"></video>
```

Keep the MP4 in the feature's `images/` folder so the path resolves like any screenshot. Preview with `mint dev` before pushing.

---

## 7. Preview the docs locally

```
npx -y mint@latest dev      # serves the docs; prints a http://localhost:<port> URL
```

(3000/3001 may be taken by other apps — it will hop to the next free port and print which.)

---

## 8. Definition of done (checklist)

- [ ] `slides.tsv` exists in `images/<feature-slug>/`, one row per screenshot, correct order.
- [ ] Every `image` in the TSV is a real file in that folder.
- [ ] Silent build renders and looks right (`build-walkthrough.sh …`).
- [ ] (If narrated) key is in a **file**, not chat/commit; cost (~$0.03) is expected; audio is non-silent.
- [ ] Output MP4 lives in the feature's `images/` folder.
- [ ] (Optional) `<video>` embedded at the top of the doc page and previewed in `mint dev`.
- [ ] Key rotated if it was ever exposed.
```
