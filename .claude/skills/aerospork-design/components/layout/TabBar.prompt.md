Use for the top-level navigation of a settings window. Tab titles are one word where possible (General, Gaps, Keys, Monitors, Events); AeroSpork's only two-word tab is "Window Rules".

~~~jsx
<TabBar value={tab} onChange={setTab} tabs={[
  { id: 'general', label: 'General', sf: 'gearshape' },
  { id: 'gaps', label: 'Gaps', sf: 'rectangle.split.3x3' },
]} />
~~~

Tab switching is instant — never animate it.
