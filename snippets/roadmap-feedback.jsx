export const RoadmapVote = ({ feature }) => {
  const [vote, setVote] = useState(0);
  const [message, setMessage] = useState('');
  const key = 'eazybe-roadmap-preview-v1:' + feature;
  useEffect(() => {
    try {
      const stored = Number(window.localStorage.getItem(key));
      setVote(stored === 1 || stored === -1 ? stored : 0);
    } catch (_) {}
  }, [key]);
  const choose = (direction) => {
    const next = vote === direction ? 0 : direction;
    setVote(next);
    try {
      window.localStorage.setItem(key, String(next));
      setMessage(next ? 'Saved on this browser only.' : 'Vote removed.');
    } catch (_) {
      setMessage('Preview vote only; browser storage is unavailable.');
    }
  };
  const buttonStyle = (active) => ({border: '1px solid ' + (active ? '#64748b' : '#d1d5db'), borderRadius: '6px', background: active ? '#e2e8f0' : '#fff', color: '#334155', padding: '5px 10px', cursor: 'pointer', fontSize: '13px'});
  return (
    <div style={{marginTop: '14px'}}>
      <div role="group" aria-label={'Vote on ' + feature} style={{display: 'flex', alignItems: 'center', gap: '8px'}}>
        <button type="button" aria-label={'Upvote ' + feature} aria-pressed={vote === 1} style={buttonStyle(vote === 1)} onClick={() => choose(1)}>↑</button>
        <span aria-label={'Preview vote score: ' + vote} aria-live="polite" style={{fontSize: '14px', fontWeight: 600, color: '#334155', minWidth: '24px', textAlign: 'center', fontVariantNumeric: 'tabular-nums'}}>{vote}</span>
        <button type="button" aria-label={'Downvote ' + feature} aria-pressed={vote === -1} style={buttonStyle(vote === -1)} onClick={() => choose(-1)}>↓</button>
      </div>
      <div role="status" style={{fontSize: '11px', color: '#64748b', marginTop: '5px'}}>{message}</div>
    </div>
  );
};

export const FeatureRequest = () => {
  const [title, setTitle] = useState('');
  const [details, setDetails] = useState('');
  const [message, setMessage] = useState('');
  const fieldStyle = {display: 'block', width: '100%', boxSizing: 'border-box', border: '1px solid #cbd5e1', borderRadius: '8px', padding: '10px 12px', background: '#fff', color: '#1f2937', fontSize: '14px', marginTop: '6px'};
  const compose = (event) => {
    event.preventDefault();
    if (!title.trim() || !details.trim()) { setMessage('Add a feature title and describe what you need.'); return; }
    const subject = encodeURIComponent('Eazybe feature request: ' + title.trim());
    const body = encodeURIComponent('Feature: ' + title.trim() + '\n\nWhat I need:\n' + details.trim());
    window.location.href = 'mailto:support@eazybe.com?subject=' + subject + '&body=' + body;
    setMessage('Your email app will open with this request. Send the email to share it with Eazybe. If it does not open, email support@eazybe.com.');
  };
  return (
    <div id="feature-request" style={{border: '1px solid #cbd5e1', borderRadius: '12px', padding: '24px', marginTop: '32px', scrollMarginTop: '140px'}}>
      <h2 style={{margin: '0 0 8px', fontSize: '20px'}}>What would you like us to build?</h2>
      <p style={{fontSize: '14px', margin: '0 0 20px'}}>Share a feature or requirement and explain how it would help your team.</p>
      <form onSubmit={compose}>
        <label htmlFor="request-title" style={{display: 'block', fontSize: '14px', fontWeight: 600}}>Feature or requirement</label>
        <input id="request-title" required maxLength={120} value={title} onChange={e => setTitle(e.target.value)} placeholder="For example: assign new chats automatically" style={fieldStyle} />
        <label htmlFor="request-details" style={{display: 'block', marginTop: '16px', fontSize: '14px', fontWeight: 600}}>What do you need it to do?</label>
        <textarea id="request-details" required maxLength={2000} rows={4} value={details} onChange={e => setDetails(e.target.value)} placeholder="Describe the problem, your current workaround, and the result you need." style={fieldStyle} />
        <p style={{fontSize: '12px', opacity: 0.7, margin: '8px 0 16px'}}>Opens your email app. You review and send the request to support@eazybe.com.</p>
        <button type="submit" style={{background: '#334155', color: '#fff', borderRadius: '8px', border: 'none', padding: '10px 16px', fontSize: '14px', cursor: 'pointer'}}>Compose feature request ↗</button>
        <p role="status" style={{fontSize: '13px', marginTop: '12px'}}>{message}</p>
      </form>
    </div>
  );
};
