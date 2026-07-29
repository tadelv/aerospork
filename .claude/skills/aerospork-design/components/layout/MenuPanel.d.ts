import * as React from 'react';

/**
 * AppKit menu panel — the MenuBarExtra menu and pull-down menus.
 * @startingPoint section="Menu bar" subtitle="AeroSpork menu bar remote control" viewport="700x300"
 */
export interface MenuPanelItem {
  label?: React.ReactNode;
  /** Renders a hairline separator instead of a row */
  divider?: boolean;
  /** Shows the menu checkmark (a focused workspace) */
  checked?: boolean;
  /** Monospaced label — workspace names */
  mono?: boolean;
  /** Trailing secondary text, e.g. a monitor suffix */
  suffix?: string;
  /** Right-aligned keyboard equivalent, e.g. "⌘," */
  shortcut?: string;
  disabled?: boolean;
  help?: string;
  onClick?: () => void;
}
export interface MenuPanelProps {
  items?: MenuPanelItem[];
  width?: number;
  style?: React.CSSProperties;
}
export function MenuPanel(props: MenuPanelProps): React.JSX.Element;
