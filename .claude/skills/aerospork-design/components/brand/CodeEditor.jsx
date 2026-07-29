import React from 'react';

/* Editable text that is code, not prose: 12px monospaced, 10/12px container inset, on
   textBackgroundColor. In the app this is an NSTextView with every macOS text substitution
   turned off — smart quotes would turn a valid TOML string into an invalid one. */
export function CodeEditor({ value = '', onChange, readOnly = false, style }) {
  return (
    <textarea
      value={value} readOnly={readOnly} spellCheck={false}
      onChange={(e) => onChange && onChange(e.target.value)}
      style={{
        flex: 1, width: '100%', minHeight: 120, boxSizing: 'border-box', resize: 'none',
        border: 'none', outline: 'none', background: 'var(--text-bg)',
        color: 'var(--label)', padding: '12px 10px',
        fontFamily: 'var(--font-mono)', fontSize: 'var(--text-callout)', lineHeight: 1.45,
        tabSize: 4, ...style,
      }}
    />
  );
}
