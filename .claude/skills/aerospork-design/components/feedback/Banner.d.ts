import * as React from 'react';

/** Persistent, non-dismissible banner pinned above a window's content. */
export interface BannerProps {
  /** error = config not loaded (red); warning = config warnings (orange) */
  kind?: 'error' | 'warning';
  children?: React.ReactNode;
}
export function Banner(props: BannerProps): React.JSX.Element;
