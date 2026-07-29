import * as React from 'react';

/** Empty state for a list, table or detail pane. */
export interface ContentUnavailableProps {
  /** SF Symbol name matching the thing that is missing */
  sf?: string;
  title: string;
  /** One sentence explaining what this list is for, not that it is empty */
  message?: React.ReactNode;
  actionTitle?: string;
  onAction?: () => void;
}
export function ContentUnavailable(props: ContentUnavailableProps): React.JSX.Element;
