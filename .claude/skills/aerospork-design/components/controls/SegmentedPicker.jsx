import React from 'react';

/* `.pickerStyle(.segmented)` — used for short, mutually exclusive choices with 2-3 options
   (layout, split direction, the Keys mode switcher). */
export function SegmentedPicker({ options = [], value, onChange, style }) {
  return (
    <div style={{
      display: 'inline-flex', padding: 2, gap: 2, borderRadius: 'var(--radius-field)',
      background: 'var(--fill)', boxSizing: 'border-box', ...style,
    }}>
      {options.map((o) => {
        const v = typeof o === 'string' ? o : o.value;
        const label = typeof o === 'string' ? o : o.label;
        const on = v === value;
        return (
          <button key={v} type="button" onClick={() => onChange && onChange(v)} style={{
            font: `var(--weight-${on ? 'medium' : 'regular'}) var(--text-default)/1 var(--font-system)`,
            color: 'var(--label)', padding: '0 10px', height: 18, border: 'none',
            borderRadius: 4, cursor: 'pointer',
            background: on ? 'var(--control-bg)' : 'transparent',
            boxShadow: on ? '0 0.5px 1.5px rgba(0,0,0,.16)' : 'none',
          }}>{label}</button>
        );
      })}
    </div>
  );
}
