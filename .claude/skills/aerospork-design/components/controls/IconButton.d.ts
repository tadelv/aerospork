import * as React from 'react';

/**
 * Icon-only borderless button — the shared primitive behind every row-remove affordance.
 */
export interface IconButtonProps {
  /** SF Symbol name, e.g. "minus.circle" */
  systemImage: string;
  /** Mandatory — doubles as the title tooltip and the accessible name (aria-label) */
  label: string;
  /** Square icon size in px */
  size?: number;
  /** 'destructive' tints the icon red on hover/press only, never at rest */
  role?: 'destructive';
  onClick?: () => void;
  style?: React.CSSProperties;
}
export function IconButton(props: IconButtonProps): React.JSX.Element;
