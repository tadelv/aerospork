Use anywhere a keyboard shortcut is entered — never a plain text field asking for notation.

```jsx
<KeyRecorderField notation="alt-shift-h" recording={armed} onArm={setArmed} onClear={() => setKey('')} />
<KeyRecorderField notation={newKey} width={170} recording={rec} onArm={setRec} />
```

150px wide in a binding row (`showsClear={false}`), 170px in the composer. A filled value renders as `KeyCaps` chips internally — for a fully read-only row (a generated binding has no editable key), use `KeyCaps` directly instead of this field, or `PrettyKey(notation)` for a plain string in prose.
