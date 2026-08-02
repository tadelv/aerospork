import React from 'react';
import { SectionLabel } from './SectionLabel.jsx';

/* SectionLabel pre-wrapped with the padding a Form section header gets for free from
   .formStyle(.grouped) — for a tab whose layout isn't a Form (a list pane, a split-view list),
   so its header still lines up with a Form tab's header. Fixed: horizontal 16 / top 14 / bottom 8. */
export function PanelHeader({ title, sf, style }) {
  return <SectionLabel title={title} sf={sf} style={{ padding: 'var(--space-14) var(--space-16) var(--space-8)', ...style }} />;
}
