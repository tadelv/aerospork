import * as React from 'react';

/** Schematic screen showing how the six gap values relate. Values are in points. */
export interface GapsPreviewProps {
  innerHorizontal?: number;
  innerVertical?: number;
  outerTop?: number;
  outerBottom?: number;
  outerLeft?: number;
  outerRight?: number;
  width?: number;
  height?: number;
  /** Nominal monitor width the preview stands in for */
  nominalWidth?: number;
}
export function GapsPreview(props: GapsPreviewProps): React.JSX.Element;
