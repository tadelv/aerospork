import React from 'react';
import { BarStrip } from './BarStrip.jsx';
import { SettingsHint } from './SettingsHint.jsx';

/* A hint pinned to the bottom of a tab that has no action bar of its own to hang it off. */
export function SettingsFooter({ children }) {
  return (
    <BarStrip padded={false}>
      <SettingsHint style={{ padding: 'var(--space-9) var(--space-16)' }}>{children}</SettingsHint>
    </BarStrip>
  );
}
