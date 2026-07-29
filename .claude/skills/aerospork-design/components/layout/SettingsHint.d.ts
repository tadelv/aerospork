import * as React from 'react';

/** 12px secondary explanatory text. Backtick spans in a string child render monospaced. */
export interface SettingsHintProps {
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
export function SettingsHint(props: SettingsHintProps): React.JSX.Element;
