const { BarStrip, Icon, Button, CodeEditor, StatusLabel } = window.AeroSporkDesignSystem_078bd7;

function RawTomlTab({ toml, setToml, original }) {
  const edited = toml !== original;
  const error = /^\s*=/m.test(toml) ? 'line 3: expected a key before ‘=’' : null;
  return (
    <div className="tab-column">
      <BarStrip edge="top" padded={false}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 14px' }}>
          <span style={{ color: 'var(--label-secondary)' }}><Icon sf="doc.plaintext" size={13} /></span>
          <span className="mono" style={{ fontSize: 'var(--text-callout)', color: 'var(--label-secondary)' }}>/Users/you/.aerospork.toml</span>
          <span style={{ flex: 1 }} />
          <Button variant="borderless" title="External edits are picked up automatically — the config file is watched">Open in TextEdit</Button>
          <Button variant="borderless" title="Re-read the config file. Normally automatic.">Reload</Button>
        </div>
      </BarStrip>
      <CodeEditor value={toml} onChange={setToml} />
      <BarStrip padded={false}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 14px' }}>
          {error ? <StatusLabel kind="error">{error}</StatusLabel>
            : edited ? <StatusLabel kind="ok">Valid — press Apply (⌘S) to write it</StatusLabel>
            : <StatusLabel kind="neutral">Matches the file on disk</StatusLabel>}
          <span style={{ flex: 1 }} />
          <Button variant="borderless" title="Load a previous version of this config into the editor">Restore…</Button>
          <Button disabled={!edited} onClick={() => setToml(original)}>Revert</Button>
          <Button variant="prominent" disabled={!edited || !!error}>Apply</Button>
        </div>
      </BarStrip>
    </div>
  );
}
Object.assign(window, { RawTomlTab });
