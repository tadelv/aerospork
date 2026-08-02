import React from 'react';

/* A neutral macOS window shell for screenshots. Production delegates all title-bar material,
   contrast and accessibility behavior to NSWindow; this approximation must not invent a sheen or
   glass treatment that the app itself never draws. */
export function WindowChrome({ title, width = 880, height, children, style }) {
  const light = (bg) => ({ width: 12, height: 12, borderRadius: '50%', background: bg, boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,.12)' });
  return (
    <div style={{
      width, height, display: 'flex', flexDirection: 'column', overflow: 'hidden',
      borderRadius: 'var(--radius-window)', background: 'var(--window-bg)',
      boxShadow: 'var(--shadow-window)', ...style,
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 'var(--space-8)', height: 32,
        padding: '0 var(--space-12)', flex: '0 0 auto',
        background: 'var(--bar-bg)', backdropFilter: 'blur(var(--bar-blur))',
        WebkitBackdropFilter: 'blur(var(--bar-blur))', borderBottom: 'var(--divider)',
      }}>
        <span style={light('#ff5f57')} /><span style={light('#febc2e')} /><span style={light('#28c840')} />
        {title && <span style={{
          flex: 1, textAlign: 'center', marginRight: 52,
          fontFamily: 'var(--font-system)', fontSize: 'var(--text-default)',
          fontWeight: 'var(--weight-semibold)', color: 'var(--label)',
        }}>{title}</span>}
      </div>
      <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>{children}</div>
    </div>
  );
}
