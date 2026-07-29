import React from 'react';
import { Icon } from '../icons/Icon.jsx';

/* Borderless "copy this string" button. Flips to a checkmark for 1.4s, which is the entire
   feedback — no toast, no alert. */
export function CopyButton({ value = '', help = 'Copy to clipboard' }) {
  const [copied, setCopied] = React.useState(false);
  return (
    <button type="button" title={help} aria-label={copied ? 'Copied' : help}
      onClick={() => {
        if (navigator.clipboard) navigator.clipboard.writeText(value);
        setCopied(true);
        setTimeout(() => setCopied(false), 1400);
      }}
      style={{
        width: 18, height: 18, display: 'grid', placeItems: 'center', padding: 0,
        background: 'transparent', border: 'none', cursor: 'pointer',
        color: copied ? 'var(--sys-green)' : 'var(--label-secondary)',
      }}>
      <Icon sf={copied ? 'checkmark' : 'doc.on.doc'} size={13} />
    </button>
  );
}
