export const CountryRateTable = ({ columns, rows, label }) => {
  const [query, setQuery] = useState("");
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
      <div className="overflow-x-auto rounded-lg border border-zinc-200 dark:border-zinc-700" role="region" aria-label={label} tabIndex={0}>
        <table className="w-full text-sm">
          <caption className="sr-only">{label} — rates per delivered message</caption>
          <thead className="bg-zinc-100 dark:bg-zinc-800">
            <tr>{columns.map((column, index) => (
              <th key={column} scope="col" className={index < 2 ? "px-4 py-3 text-left font-semibold" : "px-4 py-3 text-right font-semibold"}>{column}</th>
            ))}</tr>
          </thead>
          <tbody>
            {filtered.map((row) => (
              <tr key={row[1]} className="border-t border-zinc-200 dark:border-zinc-700">
                <th scope="row" className="px-4 py-3 text-left font-medium">{row[0]}</th>
                {row.slice(1).map((value, index) => (
                  <td key={index} className={index === 0 ? "px-4 py-3 text-left" : "whitespace-nowrap px-4 py-3 text-right tabular-nums"}>{value}</td>
                ))}
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={columns.length} className="px-4 py-8 text-center text-zinc-600 dark:text-zinc-400">
                No countries match your search. Try a different country name or ISO code, or clear the search to see all destinations.
              </td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
