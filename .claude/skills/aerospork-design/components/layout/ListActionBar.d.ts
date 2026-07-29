import * as React from 'react';

/** +/- strip glued to the bottom edge of a table, optionally carrying the pane's caveat. */
export interface ListActionBarProps {
  /** Tooltip and accessibility label for + — it doubles as the button's name */
  addHelp?: string;
  removeHelp?: string;
  onAdd?: () => void;
  /** Omit (or pass null) when nothing is selected — Remove is then disabled */
  onRemove?: (() => void) | null;
  hint?: React.ReactNode;
}
export function ListActionBar(props: ListActionBarProps): React.JSX.Element;
