# Broadcast Custom Filter — Authoring Notes

- Product source: `workspace-frontend-nextjs`, branch `broadcast-custom-filter`, commit `b287a0922b0ece9f1402af32c6272d6e4a99a7ee`.
- Capture date: 26 September 2026.
- Capture source: the existing Chrome tab at `http://localhost:3000/broadcast-analytics`, operated through the installed browser extension.
- Authoring reference: `authoring/helpdoc-authoring-prompt.md`.
- Output: five verified help pages (Analytics Overview, three task guides, and View Analytics) and thirteen annotated PNGs in `images/broadcast-custom-filter/`.
- No campaigns were created or sent. The original report view and columns were restored after capture. The follow-up review only changed transient filters, search, and tabs; no campaign or communication preferences were changed.

## Image Method and Prompt Set

The built-in imagegen tool edited screenshots captured from Chrome. The images are annotated documentation derivatives, not untouched screenshot files. The source captures were reviewed before editing, and the final images were visually compared with the captured UI and its labels. Full phone numbers in the number-picker, date-control, and campaign-detail images were covered with opaque gray bars. Original unredacted captures were kept outside the docs repository.

Shared editing instructions: preserve all UI wording, data, layout, fonts, and controls; do not invent or rearrange the interface; keep text sharp; add slender tapered violet `#7065E9` arrows with triangular arrowheads and thin violet rounded outline highlights; no annotation labels or blur; output PNG.

| Asset | Additional prompt focus |
| --- | --- |
| `broadcast-overview.png` | Outline Broadcast/Template/Number; point arrows to the grouping control and sender selector; crop sidebar and outer margins. |
| `select-templates.png` | Outline the open Templates dropdown and point a tapered arrow at it; keep every template label and checkbox. |
| `template-category.png` | Outline the category dropdown, point to Marketing, preserve disabled Utility. |
| `broadcast-status.png` | Outline the open Status dropdown; point arrows to the choices and Reset filters. |
| `group-by-template.png` | Outline and point to selected Template; preserve summary counts. |
| `select-numbers.png` | Outline selected Number and the open picker; point to the picker; cover all full phone numbers with solid gray bars while preserving names, checkboxes, and Disconnected labels. |
| `date-presets.png` | Outline 1d/3d/7d/Custom and point to selected 7d; redact the sender phone number. |
| `custom-date-range.png` | Outline the two date inputs; point to the inputs and Remove date filter; preserve the dates; redact the sender phone number. |
| `choose-columns.png` | Focus on Campaign performance and Columns; outline the visible menu and point to it; preserve its partially visible Details section. |
| `sort-and-export.png` | Point to Failed's descending sort indicator, Export CSV, and Rows; outline Export CSV; retain the customized table. |
| `campaign-details.png` | Highlight campaign summary, Search contacts, and Export Total; redact sender and recipient phone numbers with opaque gray rectangles. |
| `failure-reasons.png` | Outline Failed and the failure reason; add a violet arrow; preserve the real delivery failure text and redact phone numbers. |
| `opt-out.png` | Highlight Opt Out (0), the empty contact list, and disabled export; preserve the actual empty state rather than inventing opted-out contacts. |

## Behavior Checked Against the Branch

- Only approved templates appear in the picker. Category selection replaces individual template selection; individual selection resets the category.
- Status filters campaign rows, not aggregate template totals.
- Date filters belong to Number view. Presets use UTC calendar dates including today.
- Reset filters in Number view selects all listed numbers and removes the date restriction. Remove date filter retains selected numbers.
- Column visibility persists in the browser; at least one optional column remains visible.
- CSV exports include selected columns. Broadcast exports use loaded campaign rows; template and number exports use all loaded summary rows before client pagination.

## Follow-up Content Review

All five pages were checked again against the branch and the running Chrome UI. The review expanded plain-language coverage of:

- View selection, sender selection, approved templates, multi-selection, categories, status, reset behavior, and interactions between these controls.
- The first-100-number picker limit, disconnected labels, empty selections, UTC date presets, custom dates, and removal of date restrictions.
- Metrics, column persistence, sorting scope, page sizes, pagination, CSV filenames and contents, and the differences between report CSV and recipient Excel exports.
- Campaign details, summary fields, conditional CRM information, message preview, delivery tabs, failure reasons, opt-outs, recipient search, and filtered exports.
- Loading, empty, and error states; Refresh and Retry; partial counts when campaign rows are built from paginated template message records.

The workflow-name control has no navigation handler in this version; the guide no longer promises that it opens a workflow. The campaign-detail example has zero opted-out contacts. Nonempty opt-out metadata and conditional media/CRM variants were verified from source, rather than represented as live screenshot examples. The original commented video block in `view-analytics.mdx` is preserved exactly, including its poster and video asset references.

The checkout remains at the commit above. The locally cached origin tip `4154214c` only changes analytics request gating; it does not change these controls. No checkout, pull, or frontend edits were made.

Implementation references: `src/app/broadcast-analytics/page.tsx`, `components/BroadcastsListView.tsx`, `components/BroadcastAnalyticsDetailsView.tsx`, and `components/BroadcastDetailsMessagePanel.tsx` (components under `src/app/broadcast-analytics/`), plus `src/services/wabaServices.ts`, `src/utils/communicationPreferences.ts`, and `src/utils/exportToExcel.ts` in the frontend repository.

## Validation

- All five help pages have required frontmatter and English navigation entries, and compile successfully with the installed MDX compiler.
- All seventeen procedural steps contain exactly one image. All referenced image files and internal links exist.
- The follow-up preview check returned HTTP 200 for all five updated page URLs and all thirteen PNG URLs on port 3001, and confirmed the new content was served. View Analytics was visually inspected in Chrome; all six procedural images loaded and the rendered page contained no video element.
- `git diff --check` passed; the frontend repository remained unchanged.
- The initial full-repository `mint validate` failed on existing unrelated content (118 reported MDX parse errors and 49 build warnings). None of the five touched Broadcasts pages was reported as a parse error. Full validation output was retained at `/private/tmp/broadcast-help/mint-validate.log` for this local session.
