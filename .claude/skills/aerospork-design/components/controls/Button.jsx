import React from 'react';

/* macOS push button. `bordered` is the default AppKit look; `prominent` is
   .buttonStyle(.borderedProminent) (Apply, the only prominent button in the app);
   `borderless` is .buttonStyle(.borderless), which this app uses for inline text
   actions (Override, Show, Reload) and for icon-only buttons in a bar. */
export function Button({
  children, variant = 'bordered', size = 'regular', disabled = false,
  destructive = false, iconOnly = false, title, style, onClick, ...rest
}) {
  const h = size === 'small' ? 20 : 22;
  const base = {
    font: 'var(--weight-regular) var(--text-default)/1 var(--font-system)',
    height: h, display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    gap: 'var(--space-5)', padding: iconOnly ? '0 var(--space-5)' : '0 10px',
    borderRadius: 'var(--radius-field)', cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.4 : 1, whiteSpace: 'nowrap', boxSizing: 'border-box',
  };
  const variants = {
    bordered: {
      background: 'var(--control-bg)', color: destructive ? 'var(--sys-red)' : 'var(--label)',
      border: 'var(--field-border)', boxShadow: '0 0.5px 1.5px rgba(0,0,0,.14)',
    },
    prominent: {
      background: 'var(--accent)', color: '#fff', border: '1px solid transparent',
      boxShadow: '0 0.5px 1.5px rgba(0,0,0,.18)',
    },
    borderless: {
      background: 'transparent',
      color: destructive ? 'var(--sys-red)' : 'var(--accent)',
      border: '1px solid transparent', padding: iconOnly ? 0 : '0 var(--space-2)',
    },
  };
  return (
    <button type="button" disabled={disabled} title={title} onClick={onClick}
      style={{ ...base, ...variants[variant], ...style }} {...rest}>{children}</button>
  );
}
