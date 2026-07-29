import * as React from 'react';

/** Translucent .bar chrome strip with its hairline divider on the content side. */
export interface BarStripProps {
  children?: React.ReactNode;
  /** Which edge of the content it sits on */
  edge?: 'top' | 'bottom';
  padded?: boolean;
  style?: React.CSSProperties;
}
export function BarStrip(props: BarStripProps): React.JSX.Element;
