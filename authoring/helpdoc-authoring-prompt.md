# Help-Doc Authoring — Prompt & Style Guide

> **What this is:** a reusable prompt + style guide for writing Eazybe help docs so users can **self-serve inside the product** instead of pinging sales/support for small things. Hand the prompt below (plus your screenshots) to an AI assistant, or follow it by hand. Output is Mintlify **MDX** that drops straight into this repo.

**Reference example:** the AI Agent guide under `en/ai-agents/…` was written with this playbook — a multi-page guide (Overview, Create, How it works, Knowledge, Improve) built from screenshots. Open those `.mdx` files side-by-side while you write to see the house style in practice.

---

## 1. The mindset (read first)

Write from the **product's point of view, for the user standing inside the product**. Every page should answer *"what do I click, what will I see, what happens next"* well enough that the user never has to ask a human.

- **Show the exact UI.** Quote the real button labels, headings, placeholder text, and empty-state copy the user sees on screen — verbatim, in `**bold**` or *italics*. If the screen says "Start with Bea", write "Start with Bea", not "the start button".
- **One screenshot per step.** A step the user can't visually match to their screen is a support ticket waiting to happen.
- **Answer the "little things" pre-emptively.** The tiny doubts that make users message sales — *"is this billed?", "does it send to a real number?", "why is the list empty?"* — belong in a `<Note>`/`<Warning>` right next to the relevant step.
- **Be honest about sample vs real data.** If a screen shows illustrative numbers (draft agent analytics, etc.), say so in a `<Warning>`. Never let a user think fake data is their data.
- **Neutral, calm, second person.** "You", "your agent". No hype, no "simply/just/easily" (if it were easy they wouldn't be reading the doc).

---

## 2. The prompt (copy-paste to your AI assistant)

```
You are writing a help-doc page for the Eazybe product documentation (Mintlify, MDX).

AUDIENCE: an end user who is inside the product right now and wants to do this
task themselves without contacting sales or support.

FEATURE / TASK: <name the feature or the exact job-to-be-done>

WRITE the page as MDX with:
- Frontmatter: title (Title Case, the user's goal) + one-sentence description.
- A 1–2 sentence intro stating what the user will accomplish.
- A <Steps> block. Each <Step title="Imperative action"> = one screen/action.
  * Describe exactly what the user sees, quoting real UI labels verbatim.
  * State what to click and what happens next.
  * One image per step:  ![alt](/images/<feature-slug>/<descriptive-name>.png)
- Use callouts for the "little doubts":
    <Note>   neutral clarification / tip
    <Warning> billing, irreversible actions, sample-vs-real data, gotchas
    <Tip>    optional shortcut
- If the flow is long, split into Parts as separate pages (see example) so each
  becomes its own left-sidebar entry.

TONE: calm, second person ("you"), no hype, no "simply/just". Match the voice of
the existing pages in en/ai-agents/knowledge-base-agent/creating-an-agent/.

SCREENSHOTS (in order) — for each, I give the filename and what it shows:
1. <descriptive-name>.png — <what's on screen, the labels, the one thing this step is about>
2. ...

Output ONLY the MDX. Do not invent UI that isn't in the screenshots.
```

Fill the blanks, paste your screenshot list, and you get a first draft in the house style. Then edit for accuracy against the real product.

---

## 3. Mintlify components cheat-sheet

Only use components already used in this repo (keeps rendering safe):

| Component | Use for |
|---|---|
| `<Steps> / <Step title="...">` | Any sequential task. Title = imperative ("Add a source"). |
| `![alt](/images/<slug>/<name>.png)` | One screenshot per step. Path is **from repo root**. |
| `<Note> … </Note>` | Neutral clarification, small tip, "loads from backend" caveats. |
| `<Warning> … </Warning>` | Billing, irreversible/destructive actions, **sample-vs-real data**. |
| `<Tip> … </Tip>` | Optional shortcut / power-user note. |
| `<Info> … </Info>` | Context the user should know before starting. |

Frontmatter (required, top of every page):

```mdx
---
title: "Create the Agent (Bea Wizard)"
description: "One sentence on what the user accomplishes here."
---
```

---

## 4. Images — the rules that keep them from breaking

- **One folder per feature:** `images/<feature-slug>/` (e.g. `images/creating-ai-agent/`).
- **Descriptive lowercase names**, not `image1.png`: `kb-add-source.png`, `question-primary-goal.png`. A future editor should know what a file shows from its name.
- **Reference from repo root:** `/images/<feature-slug>/<name>.png` — Mintlify resolves it there regardless of which page uses it.
- **Screenshots must be files on disk** in that folder. (Pasted-into-chat images are not files — save them first. See the video playbook's `place-agent-images.sh` for bulk copy+rename.)
- After adding a page, verify every referenced image exists:
  ```
  grep -rhoE '/images/<slug>/[a-z0-9-]+\.png' <your-page-dir>/ | sort -u
  ```
  Then check each path has a real file.

---

## 5. Wiring the page into the sidebar (`docs.json`)

Pages only appear in the site if listed in [`docs.json`](../docs.json) → `navigation.languages[en].tabs[].groups[].pages`.

- Add each page as its **relative path without `.mdx`**, e.g.
  `en/ai-agents/knowledge-base-agent/creating-an-agent/create-the-agent`.
- To make several pages show as **flat sidebar entries** (siblings), list them directly in a group's `pages` array.
- To make a collapsible **sub-section**, nest an object: `{ "group": "…", "pages": [ … ] }`.
- Add the same pages to `es` / `pt` / `tr` languages only once translations exist.

Preview locally before pushing (see video playbook for the `mint dev` command) and confirm each new page returns HTTP 200.

---

## 6. Page structure (the shape that works)

```
Frontmatter (title + description)
1–2 sentence intro — what the user will accomplish.

## Part A — <phase>            (only if the flow is long; else skip Parts)
<Steps>
  <Step title="Open …">        one screen, one image, quoted labels
  <Step title="Do …">          + <Note>/<Warning> for the little doubts
</Steps>

## Part B — <phase>
...
```

Short flow → one page. Long flow → one page per Part, each wired as its own sidebar entry (that's why the example is four files, not one).

---

## 7. Definition of done (checklist)

- [ ] Frontmatter has `title` + `description`.
- [ ] Every step has an image; every image file exists in `images/<slug>/`.
- [ ] Real UI labels quoted verbatim; no invented buttons/screens.
- [ ] Billing / irreversible / sample-data caveats are in `<Warning>`s.
- [ ] The three most common "I'd email sales about this" doubts are answered on the page.
- [ ] Page(s) added to `docs.json` nav; `mint dev` renders them at HTTP 200.
- [ ] No hype words ("simply", "just", "easily"); calm second person throughout.
- [ ] (Optional) A walkthrough video embedded at the top — see `walkthrough-video-prompt.md`.
```
