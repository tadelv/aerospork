import * as React from 'react';

/** Inset table with single-row selection. Cells may render controls (fields, pickers). */
export interface DataTableColumn {
  key: string;
  title: string;
  /** CSS grid track, e.g. "140px" or "1fr" */
  width?: string;
  render?: (row: any, selected: boolean) => React.ReactNode;
}
export interface DataTableProps {
  columns?: DataTableColumn[];
  rows?: Array<{ id: string | number; [k: string]: any }>;
  selected?: string | number | null;
  onSelect?: (id: string | number) => void;
  /** Rendered instead of the table when there are no rows — use <ContentUnavailable /> */
  emptyState?: React.ReactNode;
}
export function DataTable(props: DataTableProps): React.JSX.Element;
