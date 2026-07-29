import * as React from 'react';

/** Toolbar tab strip for a macOS settings window (SwiftUI TabView with .tabItem labels). */
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
