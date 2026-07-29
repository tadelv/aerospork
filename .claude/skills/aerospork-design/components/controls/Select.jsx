import React from 'react';

/* SwiftUI `Picker` in its default (menu) style. Options may include `{ separator: true }`
   to reproduce a `Divider()` inside the menu. */
export function Select({ options = [], value, onChange, width, mono = false, style }) {
  return (
    <div style={{ position: 'relative', display: 'inline-flex', width, ...style }}>
      <select value={value} onChange={(e) => onChange && onChange(e.target.value)} style={{
        appearance: 'none', WebkitAppearance: 'none',
        font: `var(--weight-regular) var(--text-default)/1 ${mono ? 'var(--font-mono)' : 'var(--font-system)'}`,
        color: 'var(--label)', width: '100%', height: 'var(--h-control)',
        padding: '0 22px 0 var(--space-8)', boxSizing: 'border-box',
        background: 'var(--control-bg)', border: 'var(--field-border)',
        borderRadius: 'var(--radius-field)', boxShadow: '0 0.5px 1.5px rgba(0,0,0,.14)', outline: 'none',
      }}>
        {options.map((o, i) => (typeof o === 'object' && o.separator
          ? <option key={`s${i}`} disabled>──────────</option>
          : <option key={(o.value ?? o) + '' + i} value={o.value ?? o}>{o.label ?? o}</option>))}
      </select>
      <span style={{
        position: 'absolute', right: 6, top: 0, height: '100%', display: 'grid',
        placeItems: 'center', font: '8px/1 var(--font-system)', color: 'var(--label-secondary)',
        pointerEvents: 'none',
      }}>▼</span>
    </div>
  );
}
