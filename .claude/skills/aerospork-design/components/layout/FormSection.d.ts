import * as React from 'react';

/**
 * A grouped-Form section: SectionLabel header, boxed rows, SettingsHint footer.
 * @startingPoint section="Settings" subtitle="Grouped settings form section" viewport="700x260"
 */
export interface FormSectionProps {
  /** Usually a <SectionLabel /> */
  header?: React.ReactNode;
  /** Explanatory text placed below the box; string children may use backtick code spans */
  footer?: React.ReactNode;
  /** One element per row; rows get hairline separators automatically */
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
export function FormSection(props: FormSectionProps): React.JSX.Element;
