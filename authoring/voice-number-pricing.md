# Voice number rental checker

The English billing page uses `snippets/voice-number-pricing.jsx`. It calls the
existing Nest backend at `/virtual-numbers/public/pricing/countries` and
`/virtual-numbers/public/pricing/numbers?country=US&area_code=415`.

Deploy the backend before publishing the docs change. The production base URL is
the same `/prod/api/v2` URL used by the workspace. No secret belongs in Mintlify:
the backend uses its existing Telnyx and Plivo credentials. The optional `apiUrl` component
prop allows a staging endpoint or a local test server without changing the component.

The country list comes from backend eligibility and the existing country pricing
policy. A destination in the selector is not a promise of inventory. Searches
return up to 50 available local numbers through the same API. India (`IN`) uses
Plivo; other countries use Telnyx. The backend shares the Plivo inventory adapter
with workspace checkout and uses the existing feature filters, reservation
filtering, and `getNumberSellingPrice` calculation. No provider-specific endpoint
or credential is used by the docs. Each result has
its own USD monthly rental; no provider costs or organization information are
returned. The UI displays only country and monthly rental (a range when prices
differ). Plivo quotes also use USD, matching the workspace pricing contract.
Empty stock is distinct from an API failure.

Search results are cached for five minutes in each backend process. Identical
concurrent searches share a provider request. Country policy is checked before
serving a cached result. The response checked time belongs to the provider fetch,
not the page visit. Changing provider costs appears on the next search after expiry;
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
