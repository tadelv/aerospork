import * as React from 'react';

/** Monospaced plain-text editor for TOML config. No syntax colouring, no text substitutions. */
export interface CodeEditorProps {
  value?: string;
  onChange?: (next: string) => void;
  readOnly?: boolean;
  style?: React.CSSProperties;
}
export function CodeEditor(props: CodeEditorProps): React.JSX.Element;
