import React from 'react';

/* Table(...).tableStyle(.inset): a header row of 11px secondary titles, hairline row
   separators, and a full-width accent selection. */
export function DataTable({ columns = [], rows = [], selected, onSelect, emptyState }) {
  if (!rows.length && emptyState) return emptyState;
  const grid = columns.map((c) => c.width || '1fr').join(' ');
  return (
    <div style={{ flex: 1, minHeight: 0, overflow: 'auto', background: 'var(--control-bg)' }}>
      <div style={{
        display: 'grid', gridTemplateColumns: grid, gap: 'var(--space-8)',
        padding: '4px var(--space-12)', borderBottom: 'var(--divider)',
        font: 'var(--weight-regular) var(--text-subheadline)/1.2 var(--font-system)',
        color: 'var(--label-secondary)', position: 'sticky', top: 0,
        background: 'var(--control-bg)',
      }}>
        {columns.map((c) => <span key={c.key}>{c.title}</span>)}
      </div>
      {rows.map((r) => {
        const on = selected === r.id;
        return (
          <div key={r.id} onClick={() => onSelect && onSelect(r.id)} style={{
            display: 'grid', gridTemplateColumns: grid, gap: 'var(--space-8)',
            alignItems: 'center', padding: '3px var(--space-12)',
            borderBottom: 'var(--divider)', cursor: 'default',
            background: on ? 'var(--selection)' : 'transparent',
            color: on ? 'var(--selection-fg)' : 'var(--label)',
          }}>
            {columns.map((c) => <div key={c.key} style={{ minWidth: 0 }}>{c.render ? c.render(r, on) : r[c.key]}</div>)}
          </div>
        );
      })}
    </div>
  );
}
