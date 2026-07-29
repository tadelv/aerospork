import React from 'react';
import { BarStrip } from './BarStrip.jsx';
import { SettingsHint } from './SettingsHint.jsx';
import { Icon } from '../icons/Icon.jsx';

/* The macOS "table with a +/- strip glued to its bottom edge" idiom. The caveat text lives
   inside this strip rather than in a second bar below it. */
export function ListActionBar({ addHelp = 'Add', removeHelp = 'Remove', onAdd, onRemove, hint }) {
  const btn = (sf, help, action) => (
    <button type="button" title={help} aria-label={help} disabled={!action}
      onClick={() => action && action()} style={{
        width: 20, height: 18, display: 'grid', placeItems: 'center', padding: 0,
        background: 'none', border: 'none', color: 'var(--label)',
        opacity: action ? 1 : 0.3, cursor: action ? 'pointer' : 'default',
      }}><Icon sf={sf} size={12} /></button>
  );
  return (
    <BarStrip padded={false}>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 'var(--space-10)',
        padding: '7px 12px ' + (hint ? '3px' : '7px'),
      }}>{btn('plus', addHelp, onAdd)}{btn('minus', removeHelp, onRemove)}</div>
      {hint && <SettingsHint style={{ padding: '0 var(--space-14) var(--space-9)' }}>{hint}</SettingsHint>}
    </BarStrip>
  );
}
