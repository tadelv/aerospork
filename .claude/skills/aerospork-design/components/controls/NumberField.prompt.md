Use for every numeric setting (gaps, accordion peek). Never a bare stepper — 500 clicks to cross the range was the bug this replaced.

```jsx
<NumberField title="Horizontal" value={inner} onChange={setInner} />
<NumberField title="Accordion peek" value={peek} unit="pt" max={500} onChange={setPeek} />
```

Sits inside a `FormSection`; the label is one or two words because the section header already carries the context ("Between windows" ▸ "Horizontal").
