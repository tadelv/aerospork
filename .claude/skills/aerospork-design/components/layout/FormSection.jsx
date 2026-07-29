import React from 'react';
import { SettingsHint } from './SettingsHint.jsx';

/* One Section of a grouped Form: header above, a white rounded box with hairline-separated
   rows, footer hint below. */
export function FormSection({ header, footer, children, style }) {
  const rows = React.Children.toArray(children);
  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-6)', ...style }}>
      {header && <div style={{ padding: '0 var(--space-2)' }}>{header}</div>}
      <div style={{
        background: 'var(--control-bg)', borderRadius: 'var(--radius-card)',
        boxShadow: '0 0 0 0.5px var(--separator)', overflow: 'hidden',
      }}>
        {rows.map((r, i) => (
          <div key={i} style={{
            padding: 'var(--space-8) var(--space-12)',
            borderTop: i === 0 ? 'none' : 'var(--divider)',
          }}>{r}</div>
        ))}
      </div>
      {footer && <SettingsHint style={{ padding: '0 var(--space-4)' }}>{footer}</SettingsHint>}
    </section>
  );
}
