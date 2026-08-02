Use for the top-level native pane toolbar of an application Settings window. Pane labels are one word where possible (General, Gaps, Keys, Monitors, Events); AeroSpork's only two-word label is "Window Rules".

~~~jsx
<TabBar value={tab} onChange={setTab} tabs={[
  { id: 'general', label: 'General', sf: 'gearshape' },
  { id: 'gaps', label: 'Gaps', sf: 'rectangle.split.3x3' },
]} />
~~~

Pane switching is instant — never animate it.
