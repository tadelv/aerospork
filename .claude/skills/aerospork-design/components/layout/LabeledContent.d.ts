import * as React from 'react';

/** One labelled row of a Form: text leading, control trailing. */
export interface LabeledContentProps {
  label: React.ReactNode;
  children?: React.ReactNode;
  align?: 'center' | 'flex-start';
}
export function LabeledContent(props: LabeledContentProps): React.JSX.Element;
