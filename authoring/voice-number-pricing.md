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

Both public GET routes use Nest's throttler: 10 requests per 60 seconds per route
and `request.ip`, returning 429 and Retry-After when exceeded. The installed
throttler uses process-local storage. Behind a reverse proxy, Express must resolve
the trusted client IP correctly; without trusted-proxy configuration the proxy's
IP shares the quota. Do not blindly trust user-supplied forwarding headers.
Multiple replicas have separate quotas; enforce a shared edge limit if a
deployment-wide quota is required.

Validation: backend pricing tests cover exact prices, cache expiry, country
policy, empty stock, private error suppression, DTO validation, and the 11th
request returning 429. UI fixtures use reserved example numbers only and must
never be committed as actual prices or as the production endpoint.
