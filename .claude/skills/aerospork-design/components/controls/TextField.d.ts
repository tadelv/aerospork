import * as React from 'react';

/** Single-line text entry: roundedBorder by default, plain for a search/filter field. */
export interface TextFieldProps {
  value?: string;
  onChange?: (next: string) => void;
  placeholder?: string;
  /** Monospaced — use for commands, key notation, app ids, paths */
  mono?: boolean;
  variant?: 'rounded' | 'plain';
  align?: 'left' | 'right' | 'center';
  width?: number | string;
  disabled?: boolean;
  style?: React.CSSProperties;
}
export function TextField(props: TextFieldProps): React.JSX.Element;
