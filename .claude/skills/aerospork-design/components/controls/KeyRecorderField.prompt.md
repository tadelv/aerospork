Use anywhere a keyboard shortcut is entered — never a plain text field asking for notation.

```jsx
<KeyRecorderField notation="alt-shift-h" recording={armed} onArm={setArmed} onClear={() => setKey('')} />
<KeyRecorderField notation={newKey} width={170} recording={rec} onArm={setRec} />
```

150px wide in a binding row (`showsClear={false}`), 170px in the composer. Use `PrettyKey(notation)` to render a read-only row (a generated binding has no editable key).
