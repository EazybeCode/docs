# HubSpot Segments — Authoring Notes

- Updated 6 October 2026 using `authoring/helpdoc-authoring-prompt.md`.
- Feature source: `workspace-frontend-nextjs`, `anirudh-deals-segment`, commit `e046d448`.
- Read the composer, segment picker, segment hook, and segment service for selection, pagination, phone fallback, deduplication, and error behavior.
- Screenshot source: the user's logged-in Chrome session at `https://app.eazybe.com/broadcast-messages`. The user confirmed the feature is live.
- Kept the existing `en/broadcasts/hubspot-contact-list` URL and navigation entry. Updated its title and both contact/deal procedures. Also refreshed the recipient-source paragraph, image, and guide card in `create-broadcast.mdx`.
- No broadcasts were submitted, mappings saved, or HubSpot records changed. Returned the source tab to its original AI Agents page.

## Image Method and Prompt Set

Four actual Chrome captures were cropped to the recipient panel, then annotated with the built-in imagegen tool. These are annotated screenshot derivatives. Each output was visually compared with its source for UI wording, layout, selection, and counts. No phone numbers or emails are included in the final crops. The existing broadcast-custom-filter assets supplied the violet-arrow style reference.

Shared prompt: preserve the exact UI, wording, names, values, typography, and layout; no invented controls or data; sharp readable text and no blur; remove only the pointer; add slender tapered violet `#7065E9` arrows with triangular heads and thin rounded outline highlights; keep arrows away from words; no annotation labels; high-resolution PNG output.

| File under `images/hubspot-segments/` | Focus | Output dimensions |
| --- | --- | --- |
| `contacts-browse.png` | HubSpot segment, Contacts, and contact search | 1690 × 931 |
| `contacts-selected.png` | Selected card and 2 eligible contacts of 4 resolved | 1565 × 1005 |
| `deals-browse.png` | Deals tab, deal search, and deal counts | 1720 × 914 |
| `deals-selected.png` | 10 deals versus 6 eligible contacts and association explanation | 1652 × 952 |

## Custom-Filter Branch Review

The requested `broadcast-custom-filter` feature already has five guides and thirteen annotated images in this repo. Reviewed its tip `4154214c` against the previously documented `b287a092`: the intervening change gates analytics requests by active view; it does not change documented controls. The existing guides were retained and compiled successfully: `broadcast-home`, `filter-broadcasts-and-templates`, `compare-numbers-by-date`, `customize-and-export-reports`, and `view-analytics`. Their original image provenance remains in `broadcast-custom-filter-capture-notes.md`.

## Validation

- Both edited MDX pages compile; referenced image files and internal Markdown links exist.
- Four procedural steps in the HubSpot page have one image each.
- Existing English navigation resolves to the renamed title without changing the URL.
- Mintlify preview returns HTTP 200 for both edited pages and all four new images.
- Chrome visual inspection confirmed the rendered Deals section and all four images loaded at their expected dimensions.
- Preview startup reported existing unrelated missing-navigation-page warnings. The updated page renders successfully.
- No commit, push, or production deployment was performed.

## Variable-Mapping Follow-up

Reviewed `origin/anirudh-deals-segment` at `84977a28`, specifically `hubspotVariableMapping.ts`, `HubSpotVariableMappingPanel.tsx`, and the composer mapping state in `page.tsx`. Updated the segment guide and linked template-variable guide: workspace templates support contact properties for contact segments and deal properties for deal segments; each variable needs a property and fallback; mappings are broadcast-scoped and do not overwrite saved template mappings. The mapping panel also applies to other template types with numbered body variables. Existing screenshots were retained; no new mapping screenshot was captured in this follow-up.

## Template-Specific Mapping Screenshots

Captured both user-requested templates in the live app on 6 October 2026. `hubspot_fallback` with a contact segment shows City / call_fallback and Country/Region / country_fallback suggestions. `workspace_variable_new` with a deal segment shows three unmapped variables, Deal properties, and required fallback fields. Captures were cropped to the mapping panels and annotated with the built-in imagegen tool; all visible wording, counts, and field values were compared to the originals. Shared prompt: preserve exact UI and values, remove the pointer, keep text sharp, add slender violet #7065E9 arrows and rounded outlines without covering words. HubSpot image highlights City and its fallback; workspace image highlights Deal properties, the property picker, and required fallback in the third variable. Saved as `hubspot-fallback-mapping.png` and `workspace-variable-new-mapping.png` in `images/hubspot-segments/`, referenced in both help pages. No broadcast was sent or mappings saved; restored the user's original hubspot_fallback template and Upload a list source.
