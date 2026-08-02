import * as React from 'react';

export interface SampleApp {
  id: string;
  name: string;
  glyph: string;
  tint: [string, string];
}
/** Built-in illustrative directory (Mail, Safari, Ghostty, Spotify, Slack, Finder, System
 * Settings) — NOT a real app-icon library. See AppIcon.jsx's header comment: the real Swift app
 * must resolve icons via NSWorkspace at runtime instead of bundling art. */
export declare const SAMPLE_APPS: SampleApp[];
/** Best-effort display name for a bundle ID: SAMPLE_APPS, else its last dotted path component. */
export function appDisplayName(appId?: string | null): string;
export interface AppIconProps {
  /** Bundle identifier, e.g. "com.apple.mail". Empty/null renders a generic "any app" glyph;
   * a non-empty ID outside SAMPLE_APPS renders a monogram fallback. */
  appId?: string | null;
  size?: number;
  style?: React.CSSProperties;
}
/** Placeholder app-icon tile — mock-only; see the file header for the real NSWorkspace approach. */
export function AppIcon(props: AppIconProps): React.JSX.Element;
