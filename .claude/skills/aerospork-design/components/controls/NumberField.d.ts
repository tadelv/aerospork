import * as React from 'react';

/** Numeric setting you can type into, with a unit and a stepper. Values are clamped to range. */
export interface NumberFieldProps {
  title: string;
  value?: number;
  /** Unit shown after the field; "pt" everywhere in AeroSpork */
  unit?: string;
  min?: number;
  max?: number;
  onChange?: (next: number) => void;
}
export function NumberField(props: NumberFieldProps): React.JSX.Element;
