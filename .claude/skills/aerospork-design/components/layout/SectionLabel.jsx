import React from 'react';
import { Icon } from '../icons/Icon.jsx';

/* A section header that carries an icon, so scanning down a long grouped Form gives you shape
   as well as text. A plain Section("…") header is a wall of identical grey labels. */
export function SectionLabel({ title, sf, style }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 'var(--space-6)',
      font: 'var(--weight-semibold) var(--text-headline)/1.2 var(--font-system)',
      color: 'var(--label)', ...style,
    }}>
      {sf && <Icon sf={sf} size={13} />}<span>{title}</span>
    </div>
  );
}
