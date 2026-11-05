export const CountryRateTable = ({ columns, rows, label }) => {
  const [query, setQuery] = useState("");
  const scrollArea = useRef(null);
  const [scrollbarWidth, setScrollbarWidth] = useState(0);
  useEffect(() => {
    const area = scrollArea.current;
    if (!area) return;
    area.scrollTop = 0;
    const measure = () => setScrollbarWidth(area.offsetWidth - area.clientWidth);
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(area);
    return () => observer.disconnect();
  }, [query]);
  const search = query.trim().toLowerCase();
  const filtered = rows.filter((row) =>
    row[0].toLowerCase().includes(search) || row[1].toLowerCase().includes(search)
  );
  return (
    <div className="not-prose my-6 space-y-3">
      <div className="flex items-end gap-3">
        <label className="flex-1 text-sm font-medium">
          Search by country or ISO code
          <input
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="e.g. India, United States, or GB"
            className="mt-2 block w-full rounded-lg border border-zinc-300 bg-transparent px-3 py-2 text-base text-zinc-900 focus:outline-none focus:ring-2 focus:ring-green-500 dark:border-zinc-600 dark:text-white"
          />
        </label>
        <button
          type="button"
          onClick={() => setQuery("")}
          disabled={!query}
          className="rounded-lg border border-zinc-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500 disabled:opacity-40 dark:border-zinc-600"
        >Clear</button>
      </div>
      <p role="status" aria-live="polite" className="text-sm text-zinc-600 dark:text-zinc-400">
        Showing {filtered.length} of {rows.length} destinations
      </p>
      <div
        role="table"
        aria-label={`${label} — rates per delivered message`}
        className="overflow-hidden rounded-lg border border-zinc-200 text-sm dark:border-zinc-700"
        style={{ padding: 0 }}
      >
        <div role="rowgroup" className="bg-zinc-100 dark:bg-zinc-800" style={{ margin: 0, padding: 0 }}>
          <div role="row" style={{ display: "grid", gridTemplateColumns: "minmax(0, 2fr) minmax(0, 0.6fr) minmax(0, 1fr) minmax(0, 1fr)", paddingRight: scrollbarWidth }}>
            {columns.map((column, index) => (
              <div
                key={column}
                role="columnheader"
                className={`px-4 py-3 font-semibold ${index < 2 ? "text-left" : "text-right"}`}
                style={{ minWidth: 0, overflowWrap: "anywhere" }}
              >{column}</div>
            ))}
          </div>
        </div>
        <div
          ref={scrollArea}
          role="rowgroup"
          aria-label="Scrollable rates"
          tabIndex={0}
          className="focus:outline-none focus:ring-2 focus:ring-inset focus:ring-green-500"
          style={{ maxHeight: "min(28rem, 55vh)", overflowY: "auto", overflowX: "hidden", overscrollBehavior: "contain", margin: 0, padding: 0 }}
        >
          {filtered.map((row) => (
            <div
              key={row[1]}
              role="row"
              className="border-t border-zinc-200 dark:border-zinc-700"
              style={{ display: "grid", gridTemplateColumns: "minmax(0, 2fr) minmax(0, 0.6fr) minmax(0, 1fr) minmax(0, 1fr)" }}
            >
              {row.map((value, index) => (
                <div
                  key={index}
                  role={index === 0 ? "rowheader" : "cell"}
                  className={`px-4 py-3 ${index < 2 ? "text-left" : "text-right tabular-nums"} ${index === 0 ? "font-medium" : ""}`}
                  style={{ minWidth: 0, overflowWrap: "anywhere" }}
                >{value}</div>
              ))}
            </div>
          ))}
          {filtered.length === 0 && (
            <div role="row">
              <div role="cell" aria-colspan={columns.length} className="px-4 py-8 text-center text-zinc-600 dark:text-zinc-400">
                No countries match your search. Try a different country name or ISO code, or clear the search to see all destinations.
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
