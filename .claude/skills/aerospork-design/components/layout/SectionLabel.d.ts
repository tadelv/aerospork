import * as React from 'react';

/** Icon + title header for a Form section or a pane. 13px semibold. */
export interface SectionLabelProps {
  title: string;
  /** SF Symbol name, e.g. "power", "display.2" */
  sf?: string;
  style?: React.CSSProperties;
}
export function SectionLabel(props: SectionLabelProps): React.JSX.Element;
