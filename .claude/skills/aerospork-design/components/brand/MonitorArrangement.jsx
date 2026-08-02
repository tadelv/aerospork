import React from 'react';

/* A schematic "Displays preference pane" diagram: one rectangle per connected monitor, scaled
   and positioned from its real `rect` (topLeftX/Y, width, height — points, top-left origin, the
   same numbers `aerospork list-monitors --format '%{monitor-fingerprint}'` prints). This is the
   thing a table of "Position 2" numbers can't give you: where a monitor actually sits relative
   to the others. Every rectangle is a real <button>, not a decorative shape, so selecting one
   works the same by click or by Tab + Enter/Space. The main monitor gets a thin accent bar along
   its top edge — the same "this is where the menu bar lives" cue macOS's own Displays pane uses,
   which is also the most direct answer to "why is this one called main". */
export function MonitorArrangement({ monitors = [], selected, onSelect, width = 560, height = 130 }) {
  if (!monitors.length) return null;
  const pad = 14;
  const minX = Math.min(...monitors.map((m) => m.rect.x));
  const minY = Math.min(...monitors.map((m) => m.rect.y));
  const maxX = Math.max(...monitors.map((m) => m.rect.x + m.rect.width));
  const maxY = Math.max(...monitors.map((m) => m.rect.y + m.rect.height));
  const scale = Math.min((width - pad * 2) / (maxX - minX), (height - pad * 2) / (maxY - minY));
  const offX = (width - (maxX - minX) * scale) / 2;
  const offY = (height - (maxY - minY) * scale) / 2;

  return (
    <div style={{
      position: 'relative', width, height, flex: '0 0 auto', boxSizing: 'border-box',
      borderRadius: 'var(--radius-card)', background: 'var(--fill-subtle)',
      boxShadow: 'inset 0 0 0 1px var(--border-control)',
    }}>
      {monitors.map((m, i) => {
        const on = m.id === selected;
        const w = m.rect.width * scale;
        const h = m.rect.height * scale;
        const showName = w >= 56;
        const showRes = w >= 96 && h >= 46;
        return (
          <button key={m.id} type="button" aria-pressed={on}
            aria-label={m.name + ', position ' + (i + 1) + (m.isMain ? ', main display' : '') + ', ' + m.resolution}
            title={m.name + ' — ' + m.resolution}
            onClick={() => onSelect && onSelect(m.id)}
            style={{
              position: 'absolute', left: offX + (m.rect.x - minX) * scale, top: offY + (m.rect.y - minY) * scale,
              width: w, height: h, boxSizing: 'border-box', padding: 0, margin: 0, cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2,
              background: on ? 'var(--accent-selection-fill)' : 'var(--control-bg)',
              border: on ? '1.5px solid var(--accent)' : '1px solid var(--border-control)',
              borderRadius: 'var(--radius-field)',
              boxShadow: on ? '0 2px 8px rgba(0,0,0,.14)' : '0 0.5px 1.5px rgba(0,0,0,.1)',
              transition: 'background var(--dur-control) var(--ease-standard), box-shadow var(--dur-control) var(--ease-standard)',
            }}>
            {m.isMain && (
              <span aria-hidden="true" style={{
                position: 'absolute', top: 0, left: '18%', right: '18%', height: 3,
                borderRadius: '0 0 2px 2px', background: 'var(--accent)',
              }} />
            )}
            <span aria-hidden="true" style={{
              position: 'absolute', top: 3, left: 4,
              font: 'var(--weight-medium) var(--text-caption2)/1 var(--font-mono)', color: 'var(--label-tertiary)',
            }}>{i + 1}</span>
            {showName && <span style={{
              font: 'var(--weight-medium) var(--text-caption)/1.2 var(--font-system)', color: 'var(--label)',
              maxWidth: '90%', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', textAlign: 'center',
            }}>{m.name}</span>}
            {showRes && <span style={{
              font: 'var(--weight-regular) var(--text-caption2)/1 var(--font-mono)', color: 'var(--label-tertiary)',
            }}>{m.resolution}</span>}
          </button>
        );
      })}
    </div>
  );
}
