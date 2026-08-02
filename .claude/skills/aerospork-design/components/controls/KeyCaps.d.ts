import * as React from 'react';

/** Read-only keycap-chip rendering of aerospork key notation: one bordered cap per token
    (modifier glyphs, then the key), instead of one packed mono string. */
export interface KeyCapsProps {
  /** aerospork key notation, e.g. "alt-shift-h" */
  notation?: string;
  /** Cap side in px; the cap itself is size+10 square-ish. */
  size?: number;
  /** false for use inside KeyRecorderField's own bordered container, so caps don't nest a box in a box. */
  bordered?: boolean;
}
export function KeyCaps(props: KeyCapsProps): React.JSX.Element | null;
/** Modifier notation token -> glyph, e.g. "alt" -> "⌥". Shared with KeyRecorderField's PrettyKey. */
export declare const GLYPHS: Record<string, string>;
