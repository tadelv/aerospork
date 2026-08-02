import React from 'react';
import { Icon } from '../icons/Icon.jsx';

/* The stable, non-customizable pane toolbar used by a macOS app Settings window. This is not the
   System Settings sidebar: application settings keep peer panes visible across the top and let the
   platform-selected toolbar appearance carry the current macOS material. */
export function TabBar({ tabs = [], value, onChange }) {
  return (
    <div style={{
      display: 'flex', gap: 'var(--space-2)', justifyContent: 'center', flex: '0 0 auto',
      padding: '8px var(--space-12) 9px', background: 'var(--bar-bg)',
      backdropFilter: 'blur(var(--bar-blur))', WebkitBackdropFilter: 'blur(var(--bar-blur))',
      borderBottom: 'var(--divider)', overflowX: 'auto',
    }}>
      {tabs.map((t) => {
        const on = t.id === value;
        return (
          <button key={t.id} type="button" onClick={() => onChange && onChange(t.id)} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            width: 76, padding: '5px 4px 4px', border: 'none', cursor: 'pointer',
            borderRadius: 'var(--radius-field)',
            background: on ? 'var(--fill)' : 'transparent',
            color: on ? 'var(--label)' : 'var(--label-secondary)',
            fontFamily: 'var(--font-system)', fontSize: 'var(--text-subheadline)',
            fontWeight: on ? 500 : 400, lineHeight: 1.1,
          }}>
            <Icon sf={t.sf} size={17} />
            <span style={{ whiteSpace: 'nowrap' }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}
