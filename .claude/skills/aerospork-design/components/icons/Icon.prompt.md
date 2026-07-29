Use for every glyph; pass the SF Symbol name from the Swift source so web mocks and the real app stay traceable to each other.

~~~jsx
<Icon sf="gearshape" size={14} />
<Icon sf="exclamationmark.triangle.fill" size={17} style={{ color: 'var(--sys-orange)' }} />
~~~

Icons are monochrome and inherit currentColor; tint by setting color on the parent. Never mix in emoji — AeroSpork's UI has none. The set is a Lucide SUBSTITUTION for SF Symbols (documented in readme.md ▸ Iconography); shapes are inlined, so it works offline. The same files are in assets/icons/ if you need them as assets.
