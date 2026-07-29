import * as React from 'react';

/** Borderless copy affordance that flips to a checkmark for 1.4s. */
export interface CopyButtonProps {
  /** The exact string put on the clipboard */
  value?: string;
  /** Tooltip; include the value itself when it is long (a UUID) */
  help?: string;
}
export function CopyButton(props: CopyButtonProps): React.JSX.Element;
