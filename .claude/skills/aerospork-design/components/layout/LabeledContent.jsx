import React from 'react';

/* SwiftUI LabeledContent: label on the leading edge, control trailing, one row of a Form. */
export function LabeledContent({ label, children, align = 'center' }) {
  return (
    <div style={{
      display: 'flex', alignItems: align, justifyContent: 'space-between',
      gap: 'var(--space-12)', minHeight: 'var(--h-control)',
      font: 'var(--weight-regular) var(--text-default)/1.2 var(--font-system)', color: 'var(--label)',
    }}>
      <span style={{ flex: '0 1 auto' }}>{label}</span>
      <span style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-6)', minWidth: 0 }}>{children}</span>
    </div>
  );
}
