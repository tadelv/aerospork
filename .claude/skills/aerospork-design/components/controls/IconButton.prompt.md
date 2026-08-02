Use for every icon-only row action — Remove buttons in Keys, Events (Callbacks) and anywhere else a bare `Image(systemName:)` sits inside a borderless `Button`. `label` is mandatory: write it as a name, not an instruction — `Remove “alt-h”`, not "Click to remove".

~~~jsx
<IconButton systemImage="minus.circle" role="destructive" label={'Remove “' + row.name + '”'} onClick={() => remove(row.id)} />
~~~

`role="destructive"` tints the icon red only on hover/press — it stays label-secondary at rest, matching AppKit's own borderless-destructive button rather than making the row look already wrong.
