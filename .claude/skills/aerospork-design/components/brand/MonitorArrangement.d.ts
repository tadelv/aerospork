import * as React from 'react';

/** One connected monitor. `rect` is in points, top-left origin — the same shape as
 * `Monitor.rect` in Sources/AppBundle/model/Monitor.swift. */
export interface MonitorArrangementMonitor {
  id: string | number;
  name: string;
  resolution: string;
  isMain?: boolean;
  rect: { x: number; y: number; width: number; height: number };
}
export interface MonitorArrangementProps {
  monitors: MonitorArrangementMonitor[];
  selected?: string | number | null;
  onSelect?: (id: string | number) => void;
  width?: number;
  height?: number;
}
/** Returns null when `monitors` is empty — pair with an emptyState, same as DataTable. */
export function MonitorArrangement(props: MonitorArrangementProps): React.JSX.Element | null;
