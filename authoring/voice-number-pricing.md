# Voice number rental checker

The English billing page uses `snippets/voice-number-pricing.jsx`. It calls the
existing Nest backend at `/virtual-numbers/public/pricing/countries` and
`/virtual-numbers/public/pricing/numbers?country=US&area_code=415`.

Deploy the backend before publishing the docs change. The production base URL is
the same `/prod/api/v2` URL used by the workspace. No secret belongs in Mintlify:
the backend uses its existing Telnyx credentials. The optional `apiUrl` component
prop allows a staging endpoint or a local test server without changing the component.

The country list comes from backend eligibility and the existing country pricing
policy. A destination in the selector is not a promise of inventory. Searches
return up to 50 available local numbers, using the existing Telnyx feature filters,
reservation filtering, and `getNumberSellingPrice` calculation. Each result has
its own USD monthly rental; no provider costs or organization information are
returned. Empty stock is distinct from an API failure.

Search results are cached for five minutes in each backend process. Identical
concurrent searches share a provider request. Country policy is checked before
serving a cached result. The displayed checked time belongs to the provider fetch,
not the page visit. Changing Telnyx costs appears on the next search after expiry;
the page does not poll. Checkout remains authoritative for currency, tax, billing
period, verification, availability, and the final charge.

Both public GET routes share a Redis quota of 10 requests per client IP per
60-second window across backend replicas. The 11th request returns 429 with
Retry-After. Redis failures return a temporary 503; there is no local fallback.
The backend's `PUBLIC_PRICING_TRUSTED_PROXIES` must list the actual proxy IPs/CIDRs
before deploying behind a reverse proxy. It walks only those trusted hops and
ignores spoofed forwarding headers from untrusted peers. With no configuration,
only the socket peer is used (suitable for direct/local access). All replicas must
use the same Redis and `PUBLIC_PRICING_RATE_LIMIT_NAMESPACE`; use separate
namespaces for staging and production. See the backend's
`docs/voice-number-public-pricing-rate-limit.md` for deployment and test details.

Validation: backend pricing tests cover exact prices, cache expiry, country
policy, empty stock, private error suppression, DTO validation, and the 11th
request returning 429. UI fixtures use reserved example numbers only and must
never be committed as actual prices or as the production endpoint.

## Call usage rate checker

The same English billing page also embeds `snippets/voice-usage-pricing.jsx`.
It reads number-country eligibility from `/countries`, then requests
`/usage?from_country=US&to_country=GB` only when **Check rates** is submitted.
The backend reference is `mk/feat/virtual-number/public-usage-pricing`.
Search inside the country popover filters by name or ISO code without API
requests. The dependency-free dropdown adapts shadcn combobox styling for
Mintlify; it does not install shadcn/Radix packages (which require Mintlify
Enterprise third-party libraries). It supports arrow keys, Enter, Escape,
Tab dismissal, outside clicks, and selected-item checkmarks. Domestic calling is the default. Number and destination selectors stay visible
side by side on wider screens and stack on mobile. The same-country checkbox
auto-fills the destination and keeps it in sync when the number country changes.
Choosing a different destination clears the checkbox. India is domestic-only, matching backend validation.
Destination codes come from the backend's `libphonenumber-js.getCountries()`
metadata, because a destination need not be a country where we sell numbers.
Refresh that metadata when backend destination support changes; do not replace
the number-country API with a static sales allowlist.

The response identifies `from_country` and `to_country`. Each of
`outgoing_call_per_minute`, `incoming_call_per_minute`,
`recording_per_minute`, and `sms_incoming_per_part` is an object with `usd`
and `inr` values (number or null). Display starting rates, preserve zero prices,
and show null as unavailable, including when INR conversion is unavailable.
Incoming prices depend on the number country, not the outgoing destination.
Recording is already included in call prices. Its API field is retained but
not displayed as a separate pricing row. Outgoing SMS is not offered. Prices exclude taxes.

Usage responses include `updated_at` and `stale`. The service caches rates for
24 hours and can serve last-known rates during provider failures until its
seven-day stale window ends. Show the timestamp and a visible stale notice.
This route shares the existing public pricing rate limit. Handle 429, provider
failures, timeouts, invalid responses, and retries without inventing prices.
Changing a route clears its previous result and cancels an in-flight request.
Currency switching uses the response already loaded and makes no extra request.
The optional `apiUrl` prop supports local fixtures and staging, as on the rental
checker. Deploy the usage endpoint before publishing this page.
