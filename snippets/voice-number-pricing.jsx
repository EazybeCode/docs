export const VoiceNumberPricing = ({ apiUrl = 'https://cerberus.eazybe.com/prod/api/v2/virtual-numbers/public/pricing' }) => {
  const [countries, setCountries] = useState([]);
  const [country, setCountry] = useState('US');
  const [area, setArea] = useState('');
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
      if (area.trim()) query.set('area_code', area.trim());
      const response = await fetch(`${endpoint}/numbers?${query}`, { signal: controller.signal, credentials: 'omit' });
      if (response.status === 429) throw new Error('Please wait a minute before searching again.');
      if (!response.ok) throw new Error('We could not load current rentals. Please try again or check your workspace.');
      const data = await response.json();
      if (data.country !== country || !Array.isArray(data.numbers) || !Number.isFinite(Date.parse(data.checked_at)) ||
          data.numbers.some(row => typeof row.phone_number !== 'string' || row.currency !== 'USD' ||
            !Number.isFinite(row.monthly_price) || row.monthly_price <= 0 || !Array.isArray(row.features))) throw new Error('Current rentals could not be verified. Please try again.');
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
  return (
    <section aria-label="Voice number rental checker" className="not-prose my-6 overflow-hidden rounded-2xl border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-900">
      <div className="border-b border-zinc-200 bg-green-50 px-5 py-5 dark:border-zinc-700 dark:bg-green-950/30">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="m-0 text-lg font-semibold text-zinc-900 dark:text-white">Find your monthly rental</h3>
          <span className="rounded-full border border-green-200 bg-white px-3 py-1 text-xs font-medium text-green-800 dark:border-green-800 dark:bg-green-950 dark:text-green-200">Local numbers · USD</span>
        </div>
        <p className="mb-0 mt-2 text-sm text-zinc-600 dark:text-zinc-300">Choose a destination to compare monthly rental for individual available numbers.</p>
      </div>
      <div className="space-y-5 p-5">
        {!endpoint ? (
          <p role="status" className="rounded-lg bg-zinc-50 p-4 text-sm text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">Check current rentals in <strong>CALLS → Phone Numbers → Buy a number</strong> in your Eazybe workspace. The public rental checker is not available yet.</p>
        ) : (
          <form onSubmit={search} className="grid gap-4 sm:grid-cols-2">
            <label className="text-sm font-medium text-zinc-800 dark:text-zinc-200">Country or territory
              <select value={country} onChange={event => { reset(); setCountry(event.target.value); setArea(''); }} disabled={!countries.length || status === 'loading-countries'} className={control}>
                {!countries.length && <option value="US">{status === 'loading-countries' ? 'Loading destinations…' : 'Destinations unavailable'}</option>}
                {countries.map(item => <option key={item.code} value={item.code}>{item.name} ({item.code})</option>)}
              </select>
            </label>
            <label className="text-sm font-medium text-zinc-800 dark:text-zinc-200">Area code <span className="font-normal text-zinc-500">(optional)</span>
              <input value={area} onChange={event => { reset(); setArea(event.target.value); }} inputMode="numeric" pattern="[0-9]{1,5}" maxLength={5} placeholder="e.g. 415" className={control} disabled={!countries.length} />
            </label>
            <div className="flex flex-wrap items-center gap-3 sm:col-span-2">
              <button type="submit" disabled={!countries.length || status === 'loading'} className="rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-green-800 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-50">{status === 'loading' ? 'Checking rentals…' : result ? 'Refresh rentals' : 'Check monthly rentals'}</button>
              <span className="text-xs text-zinc-500 dark:text-zinc-400">Rates cached for up to 5 minutes</span>
            </div>
          </form>
        )}
        <div aria-live="polite" role="status">
          {status === 'loading' && <p className="text-sm text-zinc-500">Finding available numbers in {name}…</p>}
          {error && <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-100">{error}{status === 'countries-error' && <button type="button" onClick={() => setRetry(value => value + 1)} className="ml-2 underline">Retry</button>}</div>}
          {result && <p className="m-0 text-sm text-zinc-600 dark:text-zinc-300">{result.numbers.length} available {result.numbers.length === 1 ? 'number' : 'numbers'} in {name} · Checked {new Date(result.checked_at).toLocaleString()}</p>}
        </div>
        {result && result.numbers.length === 0 && <p className="rounded-lg bg-zinc-50 p-4 text-sm dark:bg-zinc-800">No matching numbers are available right now. Try a different area code or destination.</p>}
        {result && result.numbers.length > 0 && <div className="max-h-96 overflow-auto rounded-xl border border-zinc-200 dark:border-zinc-700" tabIndex={0} aria-label="Available numbers and monthly rental">
          <table className="w-full whitespace-nowrap text-left text-sm">
            <thead className="sticky top-0 bg-zinc-50 text-xs uppercase tracking-wide text-zinc-500 dark:bg-zinc-800 dark:text-zinc-300"><tr><th scope="col" className="px-4 py-3">Phone number</th><th scope="col" className="px-4 py-3">Features</th><th scope="col" className="px-4 py-3 text-right">Monthly rental</th></tr></thead>
            <tbody>{result.numbers.map(row => <tr key={row.phone_number} className="border-t border-zinc-100 dark:border-zinc-800">
              <td className="px-4 py-3"><div className="font-mono font-medium text-zinc-900 dark:text-white">{row.phone_number}</div><div className="mt-1 text-xs text-zinc-500">{row.location || name}</div></td>
              <td className="px-4 py-3 text-zinc-600 dark:text-zinc-300">{row.features.map(feature => feature === 'sms' ? 'SMS' : 'Voice').join(' · ')}</td>
              <td className="px-4 py-3 text-right"><span className="font-semibold text-zinc-900 dark:text-white">${row.monthly_price.toFixed(2)}</span><span className="text-xs text-zinc-500"> / month</span></td>
            </tr>)}</tbody>
          </table>
        </div>}
        <p className="m-0 border-t border-zinc-100 pt-4 text-xs leading-5 text-zinc-500 dark:border-zinc-800 dark:text-zinc-400">Up to 50 available numbers per search. Narrow by area code to explore more. USD rental excludes taxes and call/SMS usage. Availability and prices can change; your workspace confirms eligibility, billing currency and the final amount before purchase.</p>
      </div>
    </section>
  );
};
