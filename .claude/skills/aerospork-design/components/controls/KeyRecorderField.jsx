import React from 'react';
import { Icon } from '../icons/Icon.jsx';
import { KeyCaps, GLYPHS } from './KeyCaps.jsx';

/** aerospork notation ("alt-shift-h") rendered with real modifier glyphs ("⌥⇧h").
    Capitalized because only capitalized exports reach the design-system namespace. */
export function PrettyKey(notation = '') {
  const parts = notation.split('-');
  if (parts.length < 2) return notation;
  const key = parts.pop();
  return parts.map((p) => GLYPHS[p] || p + '-').join('') + key;
}

/* Click, then press a shortcut. Armed state is accent-tinted with a 2px accent border —
   the same treatment the hand-drawn NSView uses. A filled, un-armed value renders as keycap
   chips (bordered=false, since the field itself already draws the border) rather than one run-on
   PrettyKey string — the same "one key, one cap" treatment as a read-only KeyCaps row. */
export function KeyRecorderField({ notation = '', recording = false, onArm, onClear, showsClear = true, width = 170 }) {
  const placeholder = recording ? 'Press a shortcut…' : 'Click to record';
  return (
    <div onClick={() => onArm && onArm(!recording)} style={{
      position: 'relative', width, height: 'var(--h-control)', boxSizing: 'border-box',
      display: 'flex', alignItems: 'center', padding: '0 var(--space-8)', cursor: 'pointer',
      borderRadius: 'var(--radius-recorder)',
      background: recording ? 'var(--recorder-armed-fill)' : 'var(--text-bg)',
      boxShadow: recording
        ? 'inset 0 0 0 var(--border-recorder-armed) var(--accent)'
        : 'inset 0 0 0 var(--border-hairline) var(--separator)',
      font: 'var(--weight-regular) var(--text-default)/1 var(--font-mono)',
      color: notation ? 'var(--label)' : 'var(--label-placeholder)',
    }}>
      <span style={{ overflow: 'hidden', whiteSpace: 'nowrap' }}>
        {notation ? <KeyCaps notation={notation} size={11} bordered={false} /> : placeholder}
      </span>
      {showsClear && notation && (
        <button type="button" title="Clear"
          onClick={(e) => { e.stopPropagation(); onClear && onClear(); }}
          style={{
            position: 'absolute', right: 4, top: 0, height: '100%', display: 'grid',
            placeItems: 'center', background: 'none', border: 'none', padding: 0,
            cursor: 'pointer', color: 'var(--label-tertiary)',
          }}>
          <Icon sf="xmark.circle.fill" size={12} />
        </button>
      )}
    </div>
  );
}
