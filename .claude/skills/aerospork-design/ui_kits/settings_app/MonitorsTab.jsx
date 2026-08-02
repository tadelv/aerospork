const { SectionLabel, CopyButton, Icon, DataTable, ListActionBar, TextField, Select, ContentUnavailable, Badge, Button, MonitorArrangement } = window.AeroSporkDesignSystem_078bd7;

function MonitorsTab({ monitors, assignments, setAssignments }) {
  const [selected, setSelected] = React.useState(null);
  const [selectedMonitor, setSelectedMonitor] = React.useState(null);

  const monitorOptions = [
    { value: 'main', label: 'Main' },
    { value: 'secondary', label: 'Non-main' },
    { separator: true },
    ...monitors.map((m, i) => ({ value: String(i + 1), label: `Position ${i + 1} — left to right` })),
    { separator: true },
    ...monitors.flatMap((m) => [
      // The plain name only needs disambiguating when a UUID sibling is offered right below it.
      { value: m.name, label: m.uuid ? m.name + ' — matches by name' : m.name },
      ...(m.uuid ? [{ value: m.uuid, label: m.name + ' — exact display' }] : []),
    ]),
  ];

  // Mirrors MonitorDescriptionEx.resolveMonitor (Sources/AppBundle/model/MonitorDescriptionEx.swift)
  // for the four token shapes this editor itself ever writes — main / secondary / position /
  // exact name / UUID. It does not attempt arbitrary regex patterns; those only exist in
  // hand-written Raw TOML, which is exactly what the `complex` badge already flags below.
  const resolveMonitorId = (token) => {
    if (!token) return null;
    if (token === 'main') return monitors.find((m) => m.isMain)?.id ?? null;
    if (token === 'secondary') return monitors.length === 2 ? (monitors.find((m) => !m.isMain)?.id ?? null) : null;
    const seq = Number(token);
    if (Number.isInteger(seq) && String(seq) === token && seq >= 1) return monitors[seq - 1]?.id ?? null;
    const hit = monitors.find((m) => m.uuid === token || m.name === token);
    return hit ? hit.id : null;
  };

  const update = (id, patch) => setAssignments(assignments.map((a) => (a.id === id ? { ...a, ...patch } : a)));
  const add = (monitor = 'main') => {
    const id = 'a' + Date.now();
    setAssignments([...assignments, { id, workspace: '', monitor }]);
    setSelected(id);
  };
  const remove = () => { setAssignments(assignments.filter((a) => a.id !== selected)); setSelected(null); };
  const toggleMonitor = (id) => setSelectedMonitor((cur) => (cur === id ? null : id));

  const activeMonitor = monitors.find((m) => m.id === selectedMonitor) || null;
  const pinnedHere = activeMonitor ? assignments.filter((a) => resolveMonitorId(a.monitor) === activeMonitor.id) : [];

  return (
    <div className="tab-column">
      <div className="form-page">
        <section className="monitors-section">
          <SectionLabel title="Connected monitors" sf="display.2" style={{ padding: '0 var(--space-2)' }} />
          <div className="card-surface monitors-surface">
            {monitors.length === 0 ? (
              <ContentUnavailable sf="display" title="No monitors detected"
                message="Monitors appear here as soon as macOS reports one — their UUIDs are what pins a workspace to a physical panel." />
            ) : (
              <>
                <div className="monitor-diagram-wrap">
                  <MonitorArrangement monitors={monitors} selected={selectedMonitor} onSelect={toggleMonitor} />
                </div>
                <div className="monitor-detail">
                  {activeMonitor ? (
                    <>
                      <Icon sf="display" size={13} style={{ color: 'var(--label-tertiary)', flex: '0 0 auto' }} />
                      <span>
                        <strong style={{ color: 'var(--label)', fontWeight: 'var(--weight-medium)' }}>{activeMonitor.name}</strong>
                        {pinnedHere.length === 0 ? ' — no workspaces pinned here yet.' : ' — pinned:'}
                      </span>
                      {pinnedHere.map((a) => (
                        <button key={a.id} type="button" className="workspace-chip" onClick={() => setSelected(a.id)}
                          title={'Edit ' + (a.workspace ? '“' + a.workspace + '”' : 'this assignment')}>
                          {a.workspace ? '“' + a.workspace + '”' : '(unnamed)'}
                        </button>
                      ))}
                      <span style={{ flex: 1 }} />
                      <Button onClick={() => add(activeMonitor.uuid || activeMonitor.name)}>Pin a workspace here</Button>
                    </>
                  ) : (
                    <span>Select a monitor above to see what’s pinned to it, or pin a new workspace to it directly.</span>
                  )}
                </div>
                <div className="monitor-list">
                  {monitors.map((m, i) => (
                    <div key={m.id} className={'monitor-row' + (m.id === selectedMonitor ? ' is-selected' : '')}>
                      <span className="mono" style={{ fontSize: 'var(--text-caption)', color: 'var(--label-tertiary)', width: 14, textAlign: 'right' }}>{i + 1}</span>
                      <span style={{ color: 'var(--label-secondary)', width: 26, display: 'grid', placeItems: 'center' }}><Icon sf="display" size={17} /></span>
                      <span style={{ display: 'flex', flexDirection: 'column', gap: 1, minWidth: 0 }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span style={{ fontWeight: 'var(--weight-medium)' }}>{m.name}</span>
                          {m.isMain && <Badge tone="muted" help="AeroSpork's main display — the monitor the “main” pattern matches.">main</Badge>}
                        </span>
                        <span style={{ fontSize: 'var(--text-callout)', color: 'var(--label-secondary)' }}>{m.resolution}</span>
                      </span>
                      <span style={{ flex: 1 }} />
                      <span className="mono" style={{ fontSize: 'var(--text-caption)', color: 'var(--label-tertiary)' }}>{m.uuid.slice(0, 8)}…</span>
                      <CopyButton value={m.uuid} help={'Copy display UUID\n' + m.uuid} />
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        </section>

        <section className="assignments-section">
          <SectionLabel title="Workspace assignments" sf="arrow.triangle.branch" style={{ padding: '0 var(--space-2)' }} />
          <div className="card-surface assignments-surface">
            <DataTable selected={selected} onSelect={setSelected}
              columns={[
                // Inert handle column: mirrors the real Table's leading column, which carries no
                // control so a click has somewhere to land for row selection. Decorative only.
                // A plain dot, not a drag handle -- this row can't be reordered, and
                // `line.3.horizontal` would say otherwise. Matches the real Swift's tiny 6pt
                // `circle` glyph: a near-invisible marker, not a visible icon.
                { key: 'handle', title: '', width: '20px', render: () => <span style={{ display: 'inline-block', width: 6, height: 6, borderRadius: '50%', background: 'var(--label-tertiary)' }} /> },
                { key: 'workspace', title: 'Workspace', width: '140px', render: (r) => <TextField mono value={r.workspace} placeholder="name" onChange={(v) => update(r.id, { workspace: v })} style={{ width: '100%' }} /> },
                { key: 'monitor', title: 'Monitor', render: (r) => (
                  <span style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                    <Select value={r.monitor} options={monitorOptions} onChange={(v) => update(r.id, { monitor: v })} style={{ flex: 1 }} />
                    {r.complex && <Badge help="Written with more detail than this editor can show — a fallback list of monitors, or a fingerprint keyed on more than its UUID. Any structured save in this window is refused until this changes; edit it in Raw TOML.">complex</Badge>}
                  </span>
                ) },
              ]}
              rows={assignments}
              emptyState={<ContentUnavailable sf="arrow.triangle.branch" title="No assignments"
                message="Workspaces land wherever they were last used. Add an assignment to pin one to a specific monitor."
                actionTitle="Add assignment" onAction={() => add()} />} />
            <ListActionBar addHelp="Pin a workspace to a monitor" removeHelp="Remove the selected assignment"
              onAdd={() => add()} onRemove={selected ? remove : null}
              hint="Hardware fingerprints already in your config are preserved — they just show up here under the monitor's name. A DisplayLink monitor reports no vendor or serial, so its UUID is the only thing that pins a workspace to that exact monitor. A workspace name listed here also stays available — in the menu bar, in app switching — even with no windows on it; a name bound to a key (Keys pane) does the same." />
          </div>
        </section>
      </div>
    </div>
  );
}
Object.assign(window, { MonitorsTab });
