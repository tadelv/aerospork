Use for any clickable action in an AeroSpork settings surface; `prominent` is reserved for the single primary action of a pane (Apply).

```jsx
<Button>Revert</Button>
<Button variant="prominent" disabled={!edited}>Apply</Button>
<Button variant="borderless">Override</Button>
<Button variant="borderless" destructive iconOnly title="Remove"><Icon sf="minus.circle" /></Button>
```

Variants: `bordered` (default), `prominent`, `borderless`. `destructive` tints the title red. Sizes `regular` (22px, matches a roundedBorder field) and `small`. Never put two prominent buttons in one pane.
