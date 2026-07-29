import React from 'react';

const TICK = String.fromCharCode(96);

/* The one hint style in this window: 12px secondary, with backtick code spans rendered mono. */
export function SettingsHint({ children, style }) {
  const parts = typeof children === 'string'
    ? children.split(new RegExp('(' + TICK + '[^' + TICK + ']+' + TICK + ')', 'g'))
    : [children];
  return (
    <div style={{
      font: 'var(--weight-regular) var(--text-callout)/var(--leading-prose) var(--font-system)',
      color: 'var(--label-secondary)', textWrap: 'pretty', ...style,
    }}>
      {parts.map((p, i) => (typeof p === 'string' && p.startsWith(TICK) && p.endsWith(TICK) && p.length > 2
        ? <code key={i} style={{ font: 'var(--text-callout)/1 var(--font-mono)' }}>{p.slice(1, -1)}</code>
        : <React.Fragment key={i}>{p}</React.Fragment>))}
    </div>
  );
}
