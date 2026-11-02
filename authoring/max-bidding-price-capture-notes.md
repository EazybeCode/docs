# Maximum Bidding Price — Authoring Notes

- Capture and review date: 2 November 2026.
- Guide: `authoring/helpdoc-authoring-prompt.md`.
- Help page: `en/waba/templates/max-bidding-price.mdx`, registered in the English Message Templates navigation.
- Frontend: `workspace-frontend-nextjs`, branch `template-biding`, commit `c4cc9de061f947967368c7189929468313334fe4`.
- Backend: `eazybe-nestjs-backend`, branch `template-biding`, commit `954e047ba5b14445e262b78f549ab2901a44f57d`.
- Both product repositories were inspected read-only. No branch changes, code edits, campaigns, or pricing saves were performed.

## Screenshots

Captured the existing `https://app.eazybe.com/template-preview` tab in the user's Chrome profile through the installed browser extension. Each image is 1470 × 779 pixels, above 720p HD dimensions. Browser JPEG captures were converted to PNG at their original dimensions, without upscaling, invented UI, or annotations.

The list was filtered to the existing `test1` marketing template. The price of INR 1.00 and Brazil multiplier of 1.5 were entered only in the unsaved editor, then discarded with Cancel. The final template list still showed Set max price. The save screenshot shows the review state before saving, not a completed save. The documented success and synchronization messages were checked in source.

| Image | Verified screen |
| --- | --- |
| `select-marketing-template.png` | Approved Marketing template and Set max price button |
| `enter-bid-cap.png` | Maximum price per message editor with Bid cap |
| `add-country-multiplier.png` | Brazil multiplier 1.5 and calculated INR 1.50 cap |
| `review-and-save-pricing.png` | Review state with Cancel and Save pricing |

## Evidence and Scope

Frontend source: `src/components/marketing-pricing/TemplatePricingManager.tsx`, `TemplatePricingEditor.tsx`, `BroadcastPricingPanel.tsx`, and `src/utils/marketingPricing.ts`. Backend source and contract: `docs/whatsapp-max-pricing-api.md`, the marketing-pricing module, and broadcast pricing services.

The guide covers existing-template pricing, currency, country multipliers, save behavior, broadcast pricing review, billing distinctions, and user-facing recovery. The editor was verified live; broadcast review labels and error/success behavior were verified from source. No paid send was used for verification.

Account availability is described conditionally. Internal organization identifiers, provider flags, API payloads, and operational settlement details are intentionally omitted from the end-user guide. Optional per-message multipliers and historical forecasting are not presented as universally available features. Removing a template's base cap is not documented because the existing-template editor does not expose that action.

Product-owner clarification: only INR and USD are supported for users. The help page follows this confirmed product scope and excludes MXN, even though the inspected branch contains MXN handling.

## Competitor References

- [Infobip — Max price](https://www.infobip.com/docs/whatsapp/mm-lite/max-price): reference for explaining a delivery cap and organizing base price plus optional country adjustments.
- [Sinch — WhatsApp Max Price](https://developers.sinch.com/docs/conversation/channel-support/whatsapp/max-price): reference for distinguishing the cap from a campaign budget and explaining that delivery is not guaranteed.

These references informed the explanation, not Eazybe's feature scope. Competitor enrollment steps, pricing units, roadmap claims, and API-only controls were not copied. In particular, Eazybe accepts the decimal amount per delivery, so the guide does not instruct users to convert it to an integer bid per 1,000 deliveries.

The supplied public Templates URL could not be retrieved by the web tool. The destination was verified from this repository's existing Message Templates navigation and page files.

## Validation

- Mintlify preview on port 3011 returned HTTP 200 for the new page and all four images.
- Visually inspected the rendered title, Message Templates sidebar entry, numbered steps, and screenshot layout in Chrome. All four assets loaded at 1470 × 779.
- Verified one image per step, existing internal-link targets, valid `docs.json`, and exactly one English navigation entry.
- `git diff --check` passed. Both product repositories retained clean working trees.
- Mintlify reported pre-existing missing navigation targets and parse errors in unrelated API, translated, and integration pages. These did not prevent the new page from rendering; no unrelated files were changed.
