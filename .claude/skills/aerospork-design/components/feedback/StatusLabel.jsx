import React from 'react';
import { Icon } from '../icons/Icon.jsx';

/* Label(text, systemImage:) with a semantic tint: the inline validity readout of a pane. */
export function StatusLabel({ kind = 'neutral', sf, children, style }) {
  const map = {
    ok: { color: 'var(--sys-green)', sf: 'checkmark.circle' },
    error: { color: 'var(--sys-red)', sf: 'exclamationmark.triangle.fill' },
    warning: { color: 'var(--sys-orange)', sf: 'exclamationmark.triangle.fill' },
    neutral: { color: 'var(--label-secondary)', sf: 'equal.circle' },
  };
  const s = map[kind] || map.neutral;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 'var(--space-5)',
      color: s.color, fontFamily: 'var(--font-system)', fontSize: 'var(--text-callout)',
      lineHeight: 1.3, ...style,
    }}>
      <Icon sf={sf || s.sf} size={12} />{children}
    </span>
  );
}
