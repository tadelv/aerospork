import * as React from 'react';

/** Inline status readout: tinted SF Symbol plus 12px text. */
export interface StatusLabelProps {
  kind?: 'ok' | 'error' | 'warning' | 'neutral';
  /** Override the symbol for this kind */
  sf?: string;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
export function StatusLabel(props: StatusLabelProps): React.JSX.Element;
