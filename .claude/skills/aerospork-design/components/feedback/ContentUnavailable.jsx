import React from 'react';
import { Icon } from '../icons/Icon.jsx';
import { Button } from '../controls/Button.jsx';

/* The one empty state in the app: a 34px light glyph, a headline, one sentence of prose that
   says what the thing is for, and optionally the action that creates the first one. */
export function ContentUnavailable({ sf, title, message, actionTitle, onAction }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 'var(--space-8)', padding: 'var(--pad-empty-state)', width: '100%', height: '100%',
      textAlign: 'center', fontFamily: 'var(--font-system)', boxSizing: 'border-box',
    }}>
      <span style={{ color: 'var(--label-tertiary)', marginBottom: 'var(--space-2)' }}><Icon sf={sf} size={34} weight="light" /></span>
      <div style={{ fontSize: 'var(--text-headline)', fontWeight: 'var(--weight-semibold)', color: 'var(--label)' }}>{title}</div>
      <div style={{
        fontSize: 'var(--text-callout)', color: 'var(--label-secondary)',
        maxWidth: 320, lineHeight: 'var(--leading-prose)', textWrap: 'pretty',
      }}>{message}</div>
      {actionTitle && <div style={{ paddingTop: 'var(--space-4)' }}><Button onClick={onAction}>{actionTitle}</Button></div>}
    </div>
  );
}
