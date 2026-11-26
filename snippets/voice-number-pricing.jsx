export const VoiceNumberPricing = ({ apiUrl = 'https://cerberus.eazybe.com/prod/api/v2/virtual-numbers/public/pricing' }) => {
  const [countries, setCountries] = useState([]);
  const [country, setCountry] = useState('US');
  const [countryQuery, setCountryQuery] = useState('');
  const [countryOpen, setCountryOpen] = useState(false);
  const [highlightedCountry, setHighlightedCountry] = useState(0);
  const countryList = useRef(null);
  const [result, setResult] = useState(null);
  const [status, setStatus] = useState('idle');
  const [error, setError] = useState('');
  const [retry, setRetry] = useState(0);
  const active = useRef(null);
  const endpoint = apiUrl.replace(/\/$/, '');
  const control = 'mt-2 block w-full rounded-lg border border-zinc-300 bg-white px-3 py-2.5 text-sm text-zinc-900 focus:outline-none focus:ring-2 focus:ring-green-500 dark:border-zinc-600 dark:bg-zinc-900 dark:text-white';
  useEffect(() => {
    if (!endpoint) return;
    const controller = new AbortController();
    let disposed = false;
    const timeout = setTimeout(() => controller.abort(), 20000);
    setStatus('loading-countries');
    setError('');
    fetch(`${endpoint}/countries`, { signal: controller.signal, credentials: 'omit' })
      .then(response => { if (!response.ok) throw new Error(); return response.json(); })
      .then(data => {
        if (disposed) return;
        if (!Array.isArray(data.countries) || !data.countries.length || data.countries.some(item =>
          !/^[A-Z]{2}$/.test(item.code) || typeof item.name !== 'string')) throw new Error();
        setCountries(data.countries);
        setCountry(data.countries.some(item => item.code === 'US') ? 'US' : data.countries[0].code);
        setStatus('idle');
      })
      .catch(() => { if (disposed) return; setStatus('countries-error'); setError('The rental checker is temporarily unavailable. Please retry or check prices in your workspace.'); })
      .finally(() => clearTimeout(timeout));
    return () => { disposed = true; clearTimeout(timeout); controller.abort(); };
  }, [endpoint, retry]);
  useEffect(() => () => active.current?.abort(), []);
  const reset = () => {
    active.current?.abort();
    active.current = null;
    setResult(null);
    setError('');
    setStatus('idle');
  };
  const search = async event => {
    event.preventDefault();
    active.current?.abort();
    const controller = new AbortController();
    active.current = controller;
    const timeout = setTimeout(() => controller.abort(), 20000);
    setResult(null);
    setError('');
    setStatus('loading');
    try {
      const query = new URLSearchParams({ country });
      const response = await fetch(`${endpoint}/numbers?${query}`, { signal: controller.signal, credentials: 'omit' });
      if (response.status === 429) throw new Error('Please wait a minute before searching again.');
      if (!response.ok) throw new Error('We could not load current rentals. Please try again or check your workspace.');
      const data = await response.json();
      if (data.country !== country || !Array.isArray(data.numbers) || !Number.isFinite(Date.parse(data.checked_at)) ||
          data.numbers.some(row => row.currency !== 'USD' ||
            !Number.isFinite(row.monthly_price) || row.monthly_price <= 0)) throw new Error('Current rentals could not be verified. Please try again.');
      if (active.current !== controller) return;
      setResult(data);
      setStatus('success');
    } catch (failure) {
      if (active.current !== controller) return;
      setError(controller.signal.aborted ? 'The search timed out. Please try again.' : failure.message);
      setStatus('error');
    } finally { clearTimeout(timeout); }
  };
  const name = countries.find(item => item.code === country)?.name || country;
  const filteredCountries = countries.filter(item => `${item.name} ${item.code}`.toLocaleLowerCase().includes(countryQuery.trim().toLocaleLowerCase()));
  const chooseCountry = code => {
    reset();
    setCountry(code);
    setCountryOpen(false);
    setCountryQuery('');
  };
  useEffect(() => {
    if (countryOpen) countryList.current?.children[highlightedCountry]?.scrollIntoView({ block: 'nearest' });
  }, [highlightedCountry, countryOpen]);
  const rentals = result?.numbers.map(row => row.monthly_price) || [];
  const minimum = rentals.length ? Math.min(...rentals) : 0;
  const maximum = rentals.length ? Math.max(...rentals) : 0;
  const rental = minimum === maximum ? `$${minimum.toFixed(2)}` : `$${minimum.toFixed(2)}–$${maximum.toFixed(2)}`;
  return (
    <section aria-label="Voice number rental checker" className="not-prose my-6 overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-900">
      <div className="border-b border-zinc-200 bg-green-50 px-5 py-5 dark:border-zinc-700 dark:bg-green-950/30">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="m-0 text-lg font-semibold text-zinc-900 dark:text-white">Find your monthly rental</h3>
          <span className="rounded-full border border-green-200 bg-white px-3 py-1 text-xs font-medium text-green-800 dark:border-green-800 dark:bg-green-950 dark:text-green-200">Local numbers · USD</span>
        </div>
        <p className="mb-0 mt-2 text-sm text-zinc-600 dark:text-zinc-300">Choose a country to see Eazybe’s current monthly rental.</p>
      </div>
      <div className="space-y-5 p-5">
        {!endpoint ? (
          <p role="status" className="rounded-lg bg-zinc-50 p-4 text-sm text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">Check current rentals in <strong>CALLS → Phone Numbers → Buy a number</strong> in your Eazybe workspace. The public rental checker is not available yet.</p>
        ) : (
          <form onSubmit={search} className="space-y-4">
            <div style={{ width: '100%', maxWidth: '360px' }}>
              <label htmlFor="rental-country-search" className="block text-sm font-medium text-zinc-800 dark:text-zinc-200">Choose a country</label>
              <div className="relative">
                <input id="rental-country-search" type="text" role="combobox" aria-autocomplete="list" aria-expanded={countryOpen} aria-controls="rental-country-options" aria-activedescendant={countryOpen && filteredCountries[highlightedCountry] ? `rental-country-${filteredCountries[highlightedCountry].code}` : undefined}
                  value={countryOpen ? countryQuery : countries.length ? `${name} (${country})` : ''}
                  placeholder={status === 'loading-countries' ? 'Loading countries…' : countries.length ? 'Search country name or code…' : 'Countries unavailable'}
                  autoComplete="off" disabled={!countries.length || status === 'loading-countries'}
                  onFocus={() => { setCountryOpen(true); setCountryQuery(''); setHighlightedCountry(0); }}
                  onClick={() => { if (!countryOpen) { setCountryOpen(true); setCountryQuery(''); setHighlightedCountry(0); } }}
                  onBlur={() => { setCountryOpen(false); setCountryQuery(''); }}
                  onChange={event => { setCountryQuery(event.target.value); setCountryOpen(true); setHighlightedCountry(0); }}
                  onKeyDown={event => {
                    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
                      event.preventDefault();
                      setCountryOpen(true);
                      setHighlightedCountry(index => Math.max(0, Math.min(filteredCountries.length - 1, countryOpen ? index + (event.key === 'ArrowDown' ? 1 : -1) : 0)));
                    } else if (event.key === 'Enter' && countryOpen) {
                      event.preventDefault();
                      if (filteredCountries[highlightedCountry]) chooseCountry(filteredCountries[highlightedCountry].code);
                    } else if (event.key === 'Escape') {
                      event.preventDefault(); setCountryOpen(false); setCountryQuery('');
                    }
                  }}
                  className={control} style={{ paddingRight: '3rem' }} />
                <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-zinc-500 dark:text-zinc-300" style={{ position: 'absolute', right: '1rem', top: '50%', transform: 'translateY(-50%)', width: '20px', height: '20px', pointerEvents: 'none' }}><circle cx="10.5" cy="10.5" r="6.5" /><path d="m16 16 4 4" strokeLinecap="round" /></svg>
              </div>
              {countryOpen && <div className="mt-2 overflow-hidden rounded-lg border border-zinc-200 bg-white shadow-sm dark:border-zinc-700 dark:bg-zinc-900">
                <ul id="rental-country-options" role="listbox" aria-label="Countries" ref={countryList} style={{ maxHeight: '224px', overflowY: 'auto', overscrollBehavior: 'contain', margin: 0, padding: '4px', listStyle: 'none' }}>
                  {filteredCountries.map((item, index) => <li id={`rental-country-${item.code}`} key={item.code} role="option" aria-selected={country === item.code}
                    onMouseDown={event => event.preventDefault()} onClick={() => chooseCountry(item.code)} onMouseEnter={() => setHighlightedCountry(index)}
                    className={`flex cursor-pointer items-center justify-between rounded-md px-3 py-2.5 text-sm ${highlightedCountry === index ? 'bg-green-50 text-green-900 dark:bg-green-950 dark:text-green-100' : 'text-zinc-800 dark:text-zinc-200'}`}>
                    <span>{item.name}</span><span className="ml-3 text-xs text-zinc-500">{item.code}{country === item.code ? ' ✓' : ''}</span>
                  </li>)}
                </ul>
                {!filteredCountries.length && <p role="status" className="m-0 px-4 py-3 text-sm text-zinc-500">No countries found. Try another name or code.</p>}
              </div>}
            </div>
            <div className="flex flex-wrap items-center gap-3 sm:col-span-2">
              <button type="submit" disabled={!countries.length || status === 'loading'} className="rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-green-800 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-50">{status === 'loading' ? 'Checking rentals…' : result ? 'Refresh rentals' : 'Check monthly rentals'}</button>
            </div>
          </form>
        )}
        <div aria-live="polite" role="status">
          {status === 'loading' && <p className="text-sm text-zinc-500">Checking monthly rental for {name}…</p>}
          {error && <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-100">{error}{status === 'countries-error' && <button type="button" onClick={() => setRetry(value => value + 1)} className="ml-2 underline">Retry</button>}</div>}
        </div>
        {result && rentals.length === 0 && <p className="rounded-lg bg-zinc-50 p-4 text-sm dark:bg-zinc-800">Monthly rental is currently unavailable for {name}. Please choose another country.</p>}
        {result && rentals.length > 0 && <div className="overflow-hidden rounded-xl border border-zinc-200 dark:border-zinc-700">
          <table className="w-full text-left text-sm">
            <thead className="bg-zinc-50 text-xs uppercase tracking-wide text-zinc-500 dark:bg-zinc-800 dark:text-zinc-300"><tr><th scope="col" className="px-4 py-3">Country</th><th scope="col" className="px-4 py-3 text-right">Monthly rental (USD)</th></tr></thead>
            <tbody><tr className="border-t border-zinc-100 dark:border-zinc-800">
              <th scope="row" className="px-4 py-4 font-medium text-zinc-900 dark:text-white">{name}</th>
              <td className="px-4 py-4 text-right"><span className="font-semibold text-zinc-900 dark:text-white">{rental}</span><span className="text-xs text-zinc-500"> / month</span></td>
            </tr></tbody>
          </table>
        </div>}
      </div>
    </section>
  );
};
