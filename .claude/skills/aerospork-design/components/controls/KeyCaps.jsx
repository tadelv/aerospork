import React from 'react';

export const GLYPHS = { ctrl: '⌃', alt: '⌥', shift: '⇧', cmd: '⌘' };

/* One keyboard key = one keycap chip: a real-key metaphor for a binding's key notation, read
   verbatim off the keyboard rather than parsed out of a packed mono string like "⌥⇧h". Modifiers
   render as glyphs, exactly like PrettyKey; the difference is one bordered cap per token instead
   of one run-on span, which is both more scannable in a list and more literally "what you'd
   press". Read-only: the editable equivalent is KeyRecorderField, which renders its filled state
   with this same component (bordered=false, so it doesn't nest a box inside its own box). */
export function KeyCaps({ notation = '', size = 12, bordered = true }) {
  if (!notation) return null;
  const parts = notation.split('-');
  const key = parts.pop();
  const caps = [...parts.map((p) => GLYPHS[p] || p), key.length === 1 ? key.toUpperCase() : key];
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}>
      {caps.map((c, i) => (
        <kbd key={i} style={{
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          minWidth: size + 10, height: size + 10, padding: '0 5px', boxSizing: 'border-box',
          borderRadius: 4, border: 'none', fontStyle: 'normal',
          background: bordered ? 'var(--control-bg)' : 'var(--fill)',
          boxShadow: bordered ? '0 0.5px 1.5px rgba(0,0,0,.14), inset 0 0 0 var(--border-hairline) var(--border-control)' : 'none',
          font: `var(--weight-medium) ${size}px/1 var(--font-mono)`,
          color: 'var(--label)',
        }}>{c}</kbd>
      ))}
    </span>
  );
}
