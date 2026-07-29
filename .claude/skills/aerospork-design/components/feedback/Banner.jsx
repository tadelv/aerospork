import React from 'react';
import { Icon } from '../icons/Icon.jsx';

/* The persistent banner at the top of the settings window. The startup error dialog is
   modal-and-gone; without this, an app running the bundled default keymap looks exactly like
   one running the user's config. */
export function Banner({ kind = 'warning', children }) {
  const map = {
    error: { sf: 'exclamationmark.octagon.fill', color: 'var(--sys-red)', bg: 'var(--banner-error-bg)' },
    warning: { sf: 'exclamationmark.triangle.fill', color: 'var(--sys-orange)', bg: 'var(--banner-warning-bg)' },
  };
  const s = map[kind] || map.warning;
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 'var(--space-9)',
      padding: 'var(--space-11) var(--space-14)', background: s.bg,
      borderBottom: 'var(--divider)',
      fontFamily: 'var(--font-system)', fontSize: 'var(--text-callout)',
      lineHeight: 'var(--leading-prose)', color: 'var(--label)', whiteSpace: 'pre-line',
      textWrap: 'pretty',
    }}>
      <span style={{ color: s.color, display: 'grid', placeItems: 'center', height: 17 }}>
        <Icon sf={s.sf} size={15} />
      </span>
      <div style={{ flex: 1 }}>{children}</div>
    </div>
  );
}
