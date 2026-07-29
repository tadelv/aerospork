import * as React from 'react';

/**
 * The menu bar label: one chip per monitor's visible workspace, filled when focused, plus a
 * capsule chip for an active binding mode.
 * @startingPoint section="Menu bar" subtitle="Workspace chips as drawn in the macOS menu bar" viewport="700x150"
 */
export interface WorkspaceChipItem {
  name: string;
  /** Focused workspace / active mode reads as filled; everything else as an outline */
  active?: boolean;
  /** A mode is a capsule so it can never be mistaken for a workspace */
  type?: 'workspace' | 'mode';
}
export interface WorkspaceChipsProps {
  items?: WorkspaceChipItem[];
  /** Follow the menu bar's appearance: light ink on a dark bar, dark ink on a light bar */
  ink?: 'light' | 'dark';
  /** Chip height in px; the real label rasterizes at 40 and scales */
  height?: number;
}
export function WorkspaceChips(props: WorkspaceChipsProps): React.JSX.Element;
