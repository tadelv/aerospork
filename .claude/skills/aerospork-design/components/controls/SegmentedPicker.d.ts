import * as React from 'react';

/** Segmented control for 2-3 exclusive options. */
export interface SegmentedPickerProps {
  options?: Array<string | { value: string; label: string }>;
  value?: string;
  onChange?: (next: string) => void;
  style?: React.CSSProperties;
}
export function SegmentedPicker(props: SegmentedPickerProps): React.JSX.Element;
