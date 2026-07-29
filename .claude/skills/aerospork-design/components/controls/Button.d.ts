import * as React from 'react';

/**
 * macOS push button — bordered, prominent (borderedProminent) or borderless text action.
 * @startingPoint section="Controls" subtitle="macOS buttons, toggles, fields and pickers" viewport="700x210"
 */
export interface ButtonProps {
  children?: React.ReactNode;
  /** bordered = default AppKit button; prominent = borderedProminent; borderless = inline text action */
  variant?: 'bordered' | 'prominent' | 'borderless';
  size?: 'regular' | 'small';
  disabled?: boolean;
  /** Red title, for a role: .destructive button */
  destructive?: boolean;
  /** Tighter horizontal padding for a single glyph */
  iconOnly?: boolean;
  /** .help(...) tooltip */
  title?: string;
  style?: React.CSSProperties;
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
}
export function Button(props: ButtonProps): React.JSX.Element;
