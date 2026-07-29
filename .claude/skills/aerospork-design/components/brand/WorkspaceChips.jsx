import React from 'react';

/* MenuBarLabel: which workspace is on each monitor, and which of them has focus. Chips are
   drawn, never composed from N.square.fill SF Symbols — those only exist for 0...50 and single
   capitals, so a workspace named "web" would look nothing like one named "3".
   The menu bar is monochrome and follows the MENU BAR's appearance, not the app's. */
export function WorkspaceChips({ items = [], ink = 'light', height = 22 }) {
  const color = ink === 'light' ? '#fff' : '#000';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: height * 0.125, height }}>
      {items.map((it, i) => {
        const radius = it.type === 'mode' ? height / 2 : height / 4;
        const common = {
          height, display: 'grid', placeItems: 'center',
          padding: '0 ' + (radius * 0.9) + 'px', borderRadius: radius,
          fontFamily: 'var(--font-rounded)', fontWeight: 'var(--weight-semibold)',
          fontSize: height * 0.62, letterSpacing: '.01em', boxSizing: 'border-box',
        };
        return it.active
          ? <span key={i} style={{ ...common, background: color, color: ink === 'light' ? '#000' : '#fff' }}>{it.name}</span>
          : <span key={i} style={{ ...common, color, opacity: 0.75, boxShadow: 'inset 0 0 0 ' + Math.max(height * 0.075, 1) + 'px ' + color }}>{it.name}</span>;
      })}
    </div>
  );
}
