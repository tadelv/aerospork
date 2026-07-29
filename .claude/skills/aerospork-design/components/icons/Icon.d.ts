import * as React from 'react';

/**
 * Icon glyph. Takes an SF Symbol name (as written in the Swift source) and renders the closest
 * Lucide icon as an inline currentColor SVG (shapes are inlined; no network, no CDN).
 */
export interface IconProps {
  /** SF Symbol name from the app source, e.g. "gearshape", "exclamationmark.triangle.fill" */
  sf?: string;
  /** Escape hatch: a Lucide icon name, used directly */
  name?: string;
  /** Square size in px — 13-14 inline, 17 for a banner, 34 for an empty state */
  size?: number;
  weight?: 'regular' | 'light';
  style?: React.CSSProperties;
}
export function Icon(props: IconProps): React.JSX.Element;
/** The SF Symbol -> Lucide substitution table this design system ships. */
export const SF_TO_LUCIDE: Record<string, string>;
/** Inlined glyph geometry, keyed by Lucide name. Also on disk in assets/icons/. */
export const ICON_SHAPES: Record<string, string>;
