// Dependency-free adaptation of the shadcn combobox interaction for Mintlify MDX.
export const VoiceUsageCountrySelect = ({ label, value, countries, onChange, disabled = false, searchable = true, compact = false }) => {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [highlighted, setHighlighted] = useState(0);
  const root = useRef(null);
  const trigger = useRef(null);
  const searchInput = useRef(null);
  const list = useRef(null);
  const id = `voice-pricing-${label.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
  const matches = countries.filter(item => `${item.name} ${item.code}`.toLowerCase().includes(query.trim().toLowerCase()));
  const selected = countries.find(item => item.code === value);
  const display = item => compact ? item.name : `${item.name} (${item.code})`;
  const close = (restoreFocus = false) => { setOpen(false); if (restoreFocus) trigger.current?.focus(); };
  const choose = item => { onChange(item.code); close(true); };
  const show = () => { setQuery(''); setHighlighted(Math.max(0, countries.findIndex(item => item.code === value))); setOpen(true); };
  useEffect(() => {
    if (!open) return;
    if (searchable) searchInput.current?.focus();
    const outside = event => { if (!root.current?.contains(event.target)) setOpen(false); };
    document.addEventListener('pointerdown', outside);
    return () => document.removeEventListener('pointerdown', outside);
  }, [open, searchable]);
  useEffect(() => { if (disabled) setOpen(false); }, [disabled]);
  useEffect(() => {
    if (open) list.current?.children[highlighted]?.scrollIntoView({ block: 'nearest' });
  }, [open, highlighted, query]);
  const keys = event => {
    if (event.key === 'Escape') { event.preventDefault(); close(true); }
    else if (event.key === 'Tab') close();
    else if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      if (!open) show();
      else setHighlighted(index => Math.max(0, Math.min(matches.length - 1, index + (event.key === 'ArrowDown' ? 1 : -1))));
    } else if (event.key === 'Enter' && open) {
      event.preventDefault();
      if (matches[highlighted]) choose(matches[highlighted]);
    }
  };
  return <div ref={root} className={compact ? 'min-w-0' : 'w-full min-w-0'} style={{ position: 'relative' }} onKeyDown={keys} onBlur={event => { if (!event.currentTarget.contains(event.relatedTarget)) close(); }}>
    <span id={`${id}-label`} className="mb-2 block text-sm font-medium text-zinc-900 dark:text-zinc-100">{label}</span>
    <button ref={trigger} type="button" role="combobox" aria-labelledby={`${id}-label`} aria-expanded={open} aria-controls={`${id}-list`} aria-haspopup="listbox" aria-activedescendant={open && !searchable && matches[highlighted] ? `${id}-${matches[highlighted].code}` : undefined} disabled={disabled} onClick={() => open ? close() : show()} className="flex w-full items-center justify-between gap-4 rounded-md border border-zinc-300 bg-white px-3 py-2.5 text-left text-sm font-normal text-zinc-900 shadow-sm hover:bg-zinc-50 focus:outline-none focus:ring-2 focus:ring-green-600 disabled:cursor-not-allowed disabled:opacity-50 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100 dark:hover:bg-zinc-800" style={{ minWidth: compact ? '128px' : undefined, cursor: disabled ? 'not-allowed' : 'pointer' }}>
      <span className="truncate">{selected ? display(selected) : disabled ? 'Loading countries…' : 'Select a country'}</span>
      <svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ flexShrink: 0, opacity: 0.6 }}><path d="m7 9 5-5 5 5m-10 6 5 5 5-5" strokeLinecap="round" strokeLinejoin="round" /></svg>
    </button>
    {open && <div className="rounded-md border border-zinc-200 bg-white p-1 text-zinc-950 shadow-lg dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100" style={{ position: 'absolute', top: '100%', left: 0, width: '100%', minWidth: compact ? '128px' : undefined, marginTop: '6px', zIndex: 50 }}>
      {searchable && <div className="flex items-center gap-2 border-b border-zinc-200 px-2 dark:border-zinc-700">
        <svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ flexShrink: 0, opacity: 0.5 }}><circle cx="11" cy="11" r="7" /><path d="m16 16 4 4" /></svg>
        <input ref={searchInput} role="combobox" aria-label={`Search ${label.toLowerCase()}`} aria-controls={`${id}-list`} aria-expanded={open} aria-autocomplete="list" aria-activedescendant={matches[highlighted] ? `${id}-${matches[highlighted].code}` : undefined} placeholder="Search country…" value={query} onChange={event => { setQuery(event.target.value); setHighlighted(0); }} className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-zinc-500" style={{ border: 0, boxShadow: 'none', color: 'inherit' }} />
      </div>}
      <div ref={list} id={`${id}-list`} role="listbox" aria-labelledby={`${id}-label`} className="py-1" style={{ maxHeight: '240px', overflowY: 'auto', overscrollBehavior: 'contain' }}>
        {matches.map((item, index) => <div key={item.code} id={`${id}-${item.code}`} role="option" aria-selected={item.code === value} onMouseDown={event => event.preventDefault()} onMouseMove={() => setHighlighted(index)} onClick={() => choose(item)} className={`flex cursor-pointer items-center gap-2 rounded-sm px-2 py-2 text-sm ${highlighted === index ? 'bg-zinc-100 text-zinc-900 dark:bg-zinc-800 dark:text-zinc-100' : ''}`}>
          <svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ flexShrink: 0, opacity: item.code === value ? 1 : 0 }}><path d="m5 12 4 4L19 6" strokeLinecap="round" strokeLinejoin="round" /></svg>
          <span>{display(item)}</span>
        </div>)}
      </div>
      {!matches.length && <p role="status" className="px-3 py-5 text-center text-sm text-zinc-500">No country found.</p>}
    </div>}
  </div>;
};

export const VoiceUsagePricing = ({ apiUrl = 'https://cerberus.eazybe.com/prod/api/v2/virtual-numbers/public/pricing' }) => {
  const [countries, setCountries] = useState([]);
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [sameCountry, setSameCountry] = useState(true);
  const [currency, setCurrency] = useState('usd');
  const [status, setStatus] = useState('loading-countries');
  const [error, setError] = useState('');
  const [result, setResult] = useState(null);
  const [retry, setRetry] = useState(0);
  const active = useRef(null);
  const endpoint = apiUrl.replace(/\/$/, '');
  const destinations = useMemo(() => {
    // Destination ISO codes from the backend's libphonenumber-js metadata, not number-sale eligibility.
    const destinationCodes = 'AC AD AE AF AG AI AL AM AO AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GT GU GW GY HK HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TA TC TD TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG US UY UZ VA VC VE VG VI VN VU WF WS XK YE YT ZA ZM ZW';
    const names = new Intl.DisplayNames(['en'], { type: 'region' });
    return destinationCodes.split(' ').map(code => ({ code, name: names.of(code) || code })).sort((a, b) => a.name.localeCompare(b.name));
  }, []);
  const reset = () => {
    active.current?.abort();
    active.current = null;
    setResult(null);
    setError('');
    setStatus('idle');
  };
  useEffect(() => {
    active.current?.abort();
    active.current = null;
    setResult(null);
    const controller = new AbortController();
    let disposed = false;
    const timeout = setTimeout(() => controller.abort(), 20000);
    setStatus('loading-countries');
    setError('');
    setCountries([]);
    fetch(`${endpoint}/countries`, { signal: controller.signal, credentials: 'omit' })
      .then(response => { if (!response.ok) throw new Error(); return response.json(); })
      .then(data => {
        if (disposed) return;
        if (!Array.isArray(data.countries) || !data.countries.length || data.countries.some(item => !/^[A-Z]{2}$/.test(item.code) || typeof item.name !== 'string')) throw new Error();
        setCountries(data.countries);
        const initial = data.countries.some(item => item.code === 'US') ? 'US' : data.countries[0].code;
        setFrom(initial);
        setTo(initial);
        setSameCountry(true);
        setStatus('idle');
      })
      .catch(() => { if (!disposed) { setStatus('countries-error'); setError('Countries are temporarily unavailable. Please retry.'); } })
      .finally(() => clearTimeout(timeout));
    return () => { disposed = true; clearTimeout(timeout); controller.abort(); active.current?.abort(); active.current = null; };
  }, [endpoint, retry]);
  const destination = sameCountry || from === 'IN' ? from : to;
  const name = code => destinations.find(item => item.code === code)?.name || code;
  const search = async event => {
    event.preventDefault();
    active.current?.abort();
    const controller = new AbortController();
    active.current = controller;
    const timeout = setTimeout(() => controller.abort(), 20000);
    setStatus('loading');
    setResult(null);
    setError('');
    try {
      const query = new URLSearchParams({ from_country: from, to_country: destination });
      const response = await fetch(`${endpoint}/usage?${query}`, { signal: controller.signal, credentials: 'omit' });
      if (response.status === 429) throw new Error('Too many pricing requests. Please wait a minute and try again.');
      if (!response.ok) throw new Error('Rates are temporarily unavailable for this route. Please try again.');
      const data = await response.json();
      const keys = ['outgoing_call_per_minute', 'incoming_call_per_minute', 'recording_per_minute', 'sms_incoming_per_part'];
      if (data.from_country !== from || data.to_country !== destination || !Number.isFinite(Date.parse(data.updated_at)) || typeof data.stale !== 'boolean' || keys.some(key => !data[key] || ['usd', 'inr'].some(unit => data[key][unit] !== null && (!Number.isFinite(data[key][unit]) || data[key][unit] < 0)))) throw new Error('Rates could not be verified. Please try again.');
      if (active.current !== controller) return;
      setResult(data);
      setStatus('success');
    } catch (failure) {
      if (active.current !== controller) return;
      setError(controller.signal.aborted ? 'The rate lookup timed out. Please try again.' : failure.message);
      setStatus('error');
    } finally { clearTimeout(timeout); }
  };
  const rows = [
    ['outgoing_call_per_minute', 'Outgoing calls', `${name(from)} → ${name(destination)}`, 'minute'],
    ['incoming_call_per_minute', 'Incoming calls', `Received on your ${name(from)} number`, 'minute'],
    ['sms_incoming_per_part', 'Incoming SMS', 'Per received message part, where supported.', 'part'],
  ];
  const price = amount => amount === null ? 'Unavailable' : new Intl.NumberFormat('en-US', { style: 'currency', currency: currency.toUpperCase(), minimumFractionDigits: 2, maximumFractionDigits: 6 }).format(amount);
  return <section aria-label="Call rate checker" className="not-prose my-6 rounded-2xl border border-zinc-200 bg-white text-zinc-900 dark:border-zinc-700 dark:bg-zinc-900 dark:text-white">
    <div className="rounded-t-2xl border-b border-zinc-200 bg-green-50 p-5 dark:border-zinc-700 dark:bg-green-950/30">
      <h3 className="m-0 text-lg font-semibold">Check calling rates</h3>
      <p className="mb-0 mt-2 text-sm">Choose your Voice Number country and where you want to call. Shown rates are Eazybe starting prices, before tax.</p>
    </div>
    <div className="space-y-5 p-5">
      <form onSubmit={search} className="space-y-4">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <VoiceUsageCountrySelect label="Voice Number country" value={from} countries={countries} disabled={!countries.length} onChange={value => { reset(); setFrom(value); if (sameCountry || value === 'IN') setTo(value); if (value === 'IN') setSameCountry(true); }} />
          <VoiceUsageCountrySelect label="Destination country" value={destination} countries={destinations} disabled={!countries.length || from === 'IN'} onChange={value => { reset(); setTo(value); setSameCountry(value === from); }} />
        </div>
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={sameCountry} disabled={!countries.length || from === 'IN'} onChange={event => { reset(); setSameCountry(event.target.checked); if (event.target.checked) setTo(from); }} />Call within the same country</label>
        {from === 'IN' && <p className="text-sm text-zinc-500">Indian Voice Numbers can call India only.</p>}
        <p className="text-sm text-zinc-500">Incoming rates apply to your Voice Number country. Changing the outgoing destination does not change the incoming rate.</p>
        <div className="flex flex-wrap items-end gap-3">
          <button type="submit" disabled={!countries.length || !destination || status === 'loading'} className="rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-green-800 disabled:opacity-50">{status === 'loading' ? 'Checking rates…' : result ? 'Refresh rates' : 'Check rates'}</button>
          <VoiceUsageCountrySelect label="Currency" value={currency} countries={[{ code: 'usd', name: 'USD ($)' }, { code: 'inr', name: 'INR (₹)' }]} onChange={setCurrency} searchable={false} compact />
        </div>
      </form>
      <div role="status" aria-live="polite">
        {status === 'loading-countries' && <p className="text-sm">Loading countries…</p>}
        {status === 'loading' && <p className="text-sm">Checking rates for {name(from)} → {name(destination)}…</p>}
        {error && <p className="rounded-lg bg-amber-50 p-4 text-sm text-amber-900 dark:bg-amber-950 dark:text-amber-100">{error}{status === 'countries-error' && <button type="button" onClick={() => setRetry(value => value + 1)} className="ml-2 underline">Retry</button>}</p>}
      </div>
      {result && <div className="space-y-3">
        {result.stale && <p role="status" className="rounded-lg bg-amber-50 p-3 text-sm text-amber-900 dark:bg-amber-950 dark:text-amber-100">Live rates are temporarily unavailable. Showing last known rates; refresh later.</p>}
        <div className="overflow-x-auto rounded-xl border border-zinc-200 dark:border-zinc-700"><table className="w-full text-left text-sm">
          <thead className="bg-zinc-50 dark:bg-zinc-800"><tr><th scope="col" className="px-4 py-3">Usage</th><th scope="col" className="px-4 py-3 text-right">Starting rate ({currency.toUpperCase()})</th></tr></thead>
          <tbody>{rows.map(([key, label, description, unit]) => <tr key={key} className="border-t border-zinc-200 dark:border-zinc-700"><th scope="row" className="px-4 py-4 font-medium">{label}<span className="mt-1 block text-xs font-normal text-zinc-500 dark:text-zinc-400">{description}</span></th><td className="px-4 py-4 text-right"><span className="font-semibold">{price(result[key][currency])}</span>{result[key][currency] !== null && <span className="block text-xs text-zinc-500">/ {unit}</span>}</td></tr>)}</tbody>
        </table></div>
        <p className="text-xs text-zinc-500">Rates updated: {new Date(result.updated_at).toLocaleString('en-US')}. Recording is included in call prices. INR uses the current exchange rate; unavailable prices are not zero. Final wallet charges depend on billed usage and taxes.</p>
      </div>}
    </div>
  </section>;
};
