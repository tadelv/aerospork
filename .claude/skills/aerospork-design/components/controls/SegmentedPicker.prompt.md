Use when the options are few, short and worth showing at once; use `Select` instead past three options or with long labels.

```jsx
<SegmentedPicker options={['Tiles', 'Accordion']} value={layout} onChange={setLayout} />
<SegmentedPicker options={[{value:'auto',label:'Auto'},{value:'horizontal',label:'Horizontal'},{value:'vertical',label:'Vertical'}]} value={o} onChange={setO} />
```
