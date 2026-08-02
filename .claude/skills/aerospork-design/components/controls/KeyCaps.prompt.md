Use anywhere a key combo is *displayed*, not entered — a generated binding's row, a search result, a mode's entry/exit key in prose. For an editable field, use `KeyRecorderField` instead (its filled state renders with this same component).

```jsx
<KeyCaps notation="alt-shift-h" />
<KeyCaps notation="alt-shift-h" size={11} bordered={false} />
```

One bordered cap per token: modifiers as glyphs (⌃⌥⇧⌘), the physical key last. `bordered={false}` drops the shadow/border for use inside a control that already has its own border (KeyRecorderField's filled state).
