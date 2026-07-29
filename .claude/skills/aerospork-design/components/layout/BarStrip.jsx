import React from 'react';

/* .background(.bar) — the translucent chrome strip macOS puts above or below content.
   Always paired with a hairline divider on the content side. */
export function BarStrip({ children, edge = 'bottom', padded = true, style }) {
  return (
    <div style={{
      background: 'var(--bar-bg)', backdropFilter: 'blur(var(--bar-blur))',
      WebkitBackdropFilter: 'blur(var(--bar-blur))',
      borderTop: edge === 'bottom' ? 'var(--divider)' : 'none',
      borderBottom: edge === 'top' ? 'var(--divider)' : 'none',
      padding: padded ? 'var(--pad-bar-y) var(--pad-bar-x)' : 0,
      boxSizing: 'border-box', ...style,
    }}>{children}</div>
  );
}
