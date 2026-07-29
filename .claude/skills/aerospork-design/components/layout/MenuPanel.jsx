import React from 'react';
import { Icon } from '../icons/Icon.jsx';

/* An AppKit menu: vibrant panel, 4px inset rows, checkmark column, hairline dividers and
   right-aligned key equivalents. Used by MenuBarExtra and by pull-down menus. */
export function MenuPanel({ items = [], width = 236, style }) {
  return (
    <div style={{
      width, padding: 'var(--space-4)', borderRadius: 'var(--radius-recorder)',
      background: 'var(--bar-bg)', backdropFilter: 'blur(30px)', WebkitBackdropFilter: 'blur(30px)',
      boxShadow: 'var(--shadow-menu)', fontFamily: 'var(--font-system)',
      fontSize: 'var(--text-default)', ...style,
    }}>
      {items.map((it, i) => {
        if (it.divider) return <div key={i} style={{ height: 1, background: 'var(--separator)', margin: '5px var(--space-8)' }} />;
        return (
          <div key={i} onClick={it.onClick} title={it.help} style={{
            display: 'flex', alignItems: 'center', gap: 'var(--space-6)',
            padding: '3px var(--space-8)', borderRadius: 4,
            color: it.disabled ? 'var(--label-tertiary)' : 'var(--label)',
            fontFamily: it.mono ? 'var(--font-mono)' : 'inherit', lineHeight: 1.5,
          }}>
            <span style={{ width: 13, flex: '0 0 auto' }}>
              {it.checked && <Icon sf="checkmark" size={11} />}
            </span>
            <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{it.label}</span>
            {it.suffix && <span style={{ color: 'var(--label-secondary)' }}>{it.suffix}</span>}
            {it.shortcut && <span style={{ color: 'var(--label-secondary)' }}>{it.shortcut}</span>}
          </div>
        );
      })}
    </div>
  );
}
