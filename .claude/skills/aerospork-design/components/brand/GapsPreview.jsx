import React from 'react';

/* A screen with three tiles in it. Deliberately schematic: it shows the RELATIONSHIP between
   the six gap numbers, not a to-scale rendering of any display. Gaps are drawn at the ratio
   they would have on a 1600pt-wide monitor. */
export function GapsPreview({
  innerHorizontal = 8, innerVertical = 8, outerTop = 8, outerBottom = 8,
  outerLeft = 8, outerRight = 8, width = 520, height = 156, nominalWidth = 1600,
}) {
  const s = width / nominalWidth;
  const tile = {
    flex: 1, borderRadius: 'var(--radius-tile)', background: 'var(--tile-fill)',
    boxShadow: 'inset 0 0 0 1px var(--tile-stroke)',
  };
  return (
    <div style={{
      width, height, boxSizing: 'border-box', borderRadius: 'var(--radius-card)',
      background: 'var(--fill-subtle)', boxShadow: 'inset 0 0 0 1px var(--border-control)',
      padding: (outerTop * s) + 'px ' + (outerRight * s) + 'px ' + (outerBottom * s) + 'px ' + (outerLeft * s) + 'px',
      display: 'flex', gap: innerHorizontal * s,
    }}>
      <div style={tile} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: innerVertical * s }}>
        <div style={tile} /><div style={tile} />
      </div>
    </div>
  );
}
