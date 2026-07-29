import * as React from 'react';

/** Lowercase capsule badge for row provenance ("generated", "startup"). */
export interface BadgeProps {
  children?: React.ReactNode;
  tone?: 'default' | 'muted';
  /** Tooltip — always explain what the badge means */
  help?: string;
}
export function Badge(props: BadgeProps): React.JSX.Element;
