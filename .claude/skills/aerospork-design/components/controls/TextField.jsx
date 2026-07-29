import React from 'react';

/* `.textFieldStyle(.roundedBorder)`, plus the `plain` variant used by the Keys filter.
   `mono` is the default for anything that is a command, key notation, path or app id. */
export function TextField({
  value = '', onChange, placeholder, mono = false, variant = 'rounded',
  align = 'left', width, disabled = false, style, ...rest
}) {
  const rounded = variant === 'rounded';
  return (
    <input
      value={value} placeholder={placeholder} disabled={disabled}
      onChange={(e) => onChange && onChange(e.target.value)}
      style={{
        font: `var(--weight-regular) var(--text-default)/1.2 ${mono ? 'var(--font-mono)' : 'var(--font-system)'}`,
        color: 'var(--label)', textAlign: align, width, minWidth: 0,
        height: 'var(--h-control)', boxSizing: 'border-box', padding: '0 var(--space-6)',
        background: rounded ? 'var(--text-bg)' : 'transparent',
        border: rounded ? 'var(--field-border)' : '1px solid transparent',
        borderRadius: rounded ? 'var(--radius-field)' : 0,
        boxShadow: rounded ? 'inset 0 1px 1px rgba(0,0,0,.04)' : 'none',
        outline: 'none', opacity: disabled ? 0.5 : 1, ...style,
      }}
      {...rest}
    />
  );
}
