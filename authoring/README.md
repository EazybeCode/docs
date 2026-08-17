# Authoring Playbooks (for PMs)

How we make Eazybe help docs — and their walkthrough videos — in a consistent, self-serve style, so users can solve small things inside the product instead of emailing sales/support.

## The two playbooks

| File | Use it to… |
|---|---|
| [`helpdoc-authoring-prompt.md`](helpdoc-authoring-prompt.md) | Write a **help-doc page** (Mintlify MDX) from the product's point of view. Includes a copy-paste prompt, the component/frontmatter/image rules, how to wire the sidebar, and a done-checklist. |
| [`walkthrough-video-prompt.md`](walkthrough-video-prompt.md) | Turn that page's screenshots into a **narrated or silent walkthrough video** with one command. Includes the narration prompt, the `slides.tsv` format, TTS/cost/key-safety, and how to embed the video. |

## Worked example

The AI Agent guide (under `en/ai-agents/…`) was built with these playbooks — five outcome-focused pages from 17 screenshots, plus a narrated walkthrough video. Use it as a reference for the house style once it's in the docs.

## Scripts

| Script | Purpose |
|---|---|
| [`scripts/fetch-ffmpeg.sh`](../scripts/fetch-ffmpeg.sh) | One-time: download a static `ffmpeg` (no admin/brew). |
| [`scripts/build-walkthrough.sh`](../scripts/build-walkthrough.sh) | Build the video from `images/<slug>/slides.tsv` (silent or `--narrate`). |
| [`scripts/place-agent-images.sh`](../scripts/place-agent-images.sh) | Bulk copy+rename a folder of screenshots into an images folder. |

## Fast path

```
# 1. write the doc (use helpdoc-authoring-prompt.md), drop screenshots in images/<slug>/
# 2. one-time:
bash scripts/fetch-ffmpeg.sh
# 3. create images/<slug>/slides.tsv (see the video playbook §3)
# 4. build:
bash scripts/build-walkthrough.sh images/<slug>                                  # silent
bash scripts/build-walkthrough.sh images/<slug> --narrate --key-file ~/.openai_key   # voiceover
```

> **Never commit API keys.** Keep them in a file outside the repo and pass `--key-file`. See the video playbook §5.
