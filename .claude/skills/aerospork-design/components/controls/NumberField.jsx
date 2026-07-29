import React from 'react';
import { LabeledContent } from '../layout/LabeledContent.jsx';

/* `NumberField` from SettingsChrome.swift: a typable number, a unit label and a stepper.
   Clamped, because a text field can produce anything and an out-of-range value would only
   surface later as a config validation error. */
export function NumberField({ title, value = 0, unit = 'pt', min = 0, max = 500, onChange }) {
  const set = (n) => onChange && onChange(Math.min(Math.max(n, min), max));
  const stepBtn = {
    width: 15, height: 11, display: 'grid', placeItems: 'center', cursor: 'pointer',
    background: 'var(--control-bg)', border: 'var(--field-border)',
    font: '7px/1 var(--font-system)', color: 'var(--label-secondary)', padding: 0,
  };
  return (
    <LabeledContent label={title}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-6)' }}>
        <input
          value={value} inputMode="numeric"
          onChange={(e) => set(parseInt(e.target.value || '0', 10) || 0)}
          style={{
            font: 'var(--weight-regular) var(--text-default)/1.2 var(--font-system)',
            color: 'var(--label)', textAlign: 'right', width: 'var(--w-number-field)',
            height: 'var(--h-control)', boxSizing: 'border-box', padding: '0 var(--space-6)',
            background: 'var(--text-bg)', border: 'var(--field-border)',
            borderRadius: 'var(--radius-field)', outline: 'none',
          }}
        />
        <span style={{ font: 'var(--text-callout)/1 var(--font-system)', color: 'var(--label-secondary)' }}>{unit}</span>
        <span style={{ display: 'grid', borderRadius: 4, overflow: 'hidden' }}>
          <button type="button" style={{ ...stepBtn, borderRadius: '4px 4px 0 0' }} onClick={() => set(value + 1)}>▲</button>
          <button type="button" style={{ ...stepBtn, borderTop: 'none', borderRadius: '0 0 4px 4px' }} onClick={() => set(value - 1)}>▼</button>
        </span>
      </div>
    </LabeledContent>
  );
}
