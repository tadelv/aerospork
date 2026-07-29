import * as React from 'react';

/** Shortcut recorder: click to arm, then press the combination. Displays aerospork notation with modifier glyphs. */
export interface KeyRecorderFieldProps {
  /** aerospork key notation, e.g. "alt-shift-h" */
  notation?: string;
  /** Armed — accent fill and 2px accent border */
  recording?: boolean;
  onArm?: (next: boolean) => void;
  onClear?: () => void;
  /** Off for an existing binding row: a binding with no key cannot be written */
  showsClear?: boolean;
  width?: number;
}
export function KeyRecorderField(props: KeyRecorderFieldProps): React.JSX.Element;
/** "alt-shift-h" -> "⌥⇧h". Capitalized so it is reachable on the design-system namespace. */
export function PrettyKey(notation?: string): string;
