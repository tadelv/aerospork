import React, { useState } from 'react';
import { Icon } from '../icons/Icon.jsx';

/* Icon-only .buttonStyle(.borderless) button. `label` is mandatory: it doubles as the tooltip
   and the accessible name, recreating SwiftUI's .help() + .accessibilityLabel() pair, so it is
   written as a name ("Remove “alt-h”"), not an instruction. `role="destructive"` tints the icon
   red only on hover/press — it stays label-secondary at rest, matching AppKit's own
   borderless-destructive button rather than flagging the row as already wrong. */
export function IconButton({ systemImage, label, size = 14, role, onClick, style }) {
  const [hover, setHover] = useState(false);
  const destructive = role === 'destructive';
  return (
    <button type="button" title={label} aria-label={label} onClick={onClick}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
      style={{
        height: 22, display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        padding: '0 var(--space-5)', background: 'transparent', border: '1px solid transparent',
        borderRadius: 'var(--radius-field)', cursor: 'pointer', boxSizing: 'border-box',
        color: destructive && hover ? 'var(--sys-red)' : 'var(--label-secondary)',
        ...style,
      }}>
      <Icon sf={systemImage} size={size} />
    </button>
  );
}
