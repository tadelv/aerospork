import * as React from 'react';

/** macOS switch with a leading label, as used in every grouped Form section. */
export interface ToggleProps {
  label: React.ReactNode;
  checked?: boolean;
  onChange?: (next: boolean) => void;
  disabled?: boolean;
  /** .help(...) tooltip — one short sentence, no trailing period */
  help?: string;
}
export function Toggle(props: ToggleProps): React.JSX.Element;
