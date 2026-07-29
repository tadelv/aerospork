The backbone of every AeroSpork settings tab. Each child is one row.

~~~jsx
<FormSection header={<SectionLabel title="Layout" sf="rectangle.split.3x1" />}
  footer="Auto gives wide monitors a horizontal split and tall monitors a vertical one.">
  <LabeledContent label="New workspaces use"><SegmentedPicker options={['Tiles','Accordion']} value={l} onChange={setL} /></LabeledContent>
  <NumberField title="Accordion peek" value={30} />
</FormSection>
~~~

Sits on var(--grouped-bg) with 16px page padding. Explanations go in footer, never inside the box.
