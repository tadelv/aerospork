import React from 'react';

/* Capsule badge marking where a row came from. In AeroSpork it names the one layer a binding
   can arrive from that has no line anywhere in the config file: "generated". */
export function Badge({ children, tone = 'default', help }) {
  return (
    <span title={help} style={{
      display: 'inline-block', padding: '2px var(--space-6)',
      borderRadius: 'var(--radius-pill)',
      background: tone === 'muted' ? 'rgba(142,142,147,.2)' : 'var(--fill-strong)',
      color: 'color-mix(in srgb, var(--label) 72%, transparent)', fontFamily: 'var(--font-system)',
      fontSize: 'var(--text-caption2)', lineHeight: 1.3, whiteSpace: 'nowrap',
    }}>{children}</span>
  );
}
