import React from 'react';

/* SwiftUI `Toggle` in a grouped Form: label on the left, switch on the trailing edge. */
export function Toggle({ label, checked = false, onChange, disabled = false, help }) {
  return (
    <label title={help} style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      gap: 'var(--space-12)', font: 'var(--weight-regular) var(--text-default)/1.2 var(--font-system)',
      color: 'var(--label)', opacity: disabled ? 0.4 : 1, cursor: disabled ? 'default' : 'pointer',
    }}>
      <span>{label}</span>
      <span onClick={() => !disabled && onChange && onChange(!checked)} style={{
        width: 38, height: 22, flex: '0 0 auto', borderRadius: 'var(--radius-pill)',
        background: checked ? 'var(--accent)' : 'var(--label-quaternary)',
        boxShadow: checked ? 'none' : 'inset 0 0 0 0.5px rgba(0,0,0,.06)',
        position: 'relative', transition: 'background var(--dur-control) var(--ease-standard)',
      }}>
        <span style={{
          position: 'absolute', top: 1.5, left: checked ? 18 : 1.5, width: 19, height: 19,
          borderRadius: '50%', background: '#fff', boxShadow: '0 0.5px 2px rgba(0,0,0,.28)',
          transition: 'left var(--dur-control) var(--ease-standard)',
        }} />
      </span>
    </label>
  );
}
