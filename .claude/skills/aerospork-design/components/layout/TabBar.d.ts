import * as React from 'react';

/** Stable top toolbar for the peer panes of a native macOS application Settings window. */
export interface TabBarTab {
  id: string;
  label: string;
  /** SF Symbol name */
  sf: string;
}
export interface TabBarProps {
  tabs?: TabBarTab[];
  value?: string;
  onChange?: (id: string) => void;
}
export function TabBar(props: TabBarProps): React.JSX.Element;
