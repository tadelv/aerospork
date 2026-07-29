import * as React from 'react';

/** Pull-down menu picker (SwiftUI Picker, default style). */
export interface SelectProps {
  options?: Array<string | { value: string; label: string } | { separator: true }>;
  value?: string;
  onChange?: (next: string) => void;
  width?: number | string;
  /** Monospaced options — monitor UUIDs, workspace names */
  mono?: boolean;
  style?: React.CSSProperties;
}
export function Select(props: SelectProps): React.JSX.Element;
