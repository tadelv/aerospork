Use for any typed value in settings; set `mono` whenever the value is code (a command, a bundle id, a regex, a path).

```jsx
<TextField mono placeholder="command, e.g. focus left" value={cmd} onChange={setCmd} />
<TextField variant="plain" placeholder="Filter" width={150} value={q} onChange={setQ} />
```

Placeholders show a real example (`com.apple.finder`, `move-node-to-workspace 3`) or say the field is optional — never "Enter a value".
