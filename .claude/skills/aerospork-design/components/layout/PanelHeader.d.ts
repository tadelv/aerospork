import * as React from 'react';

/**
 * SectionLabel with the fixed panel-header padding (16/14/8) a non-Form pane needs to line up
 * with a Form section header.
 */
export interface PanelHeaderProps {
  title: string;
  sf?: string;
  style?: React.CSSProperties;
}
export function PanelHeader(props: PanelHeaderProps): React.JSX.Element;
