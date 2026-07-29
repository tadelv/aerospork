import * as React from 'react';

/**
 * macOS window shell (traffic lights, translucent title bar, window shadow) for framing a screen.
 * @startingPoint section="Settings" subtitle="Framed macOS window shell" viewport="700x420"
 */
export interface WindowChromeProps {
  /** Centred title; omit for a window with a toolbar-only title bar */
  title?: string;
  width?: number | string;
  height?: number | string;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
export function WindowChrome(props: WindowChromeProps): React.JSX.Element;
