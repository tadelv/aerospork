Use for the Monitors tab's spatial overview — real monitor `rect` data (points, top-left origin) laid out to scale, instead of a table of position numbers a user has to mentally map. Pair with a `selected`/`onSelect` pair driving the surrounding detail UI.

~~~jsx
<MonitorArrangement monitors={monitors} selected={selectedMonitorId} onSelect={setSelectedMonitorId} />
~~~

Every rectangle is a real `<button>` — click or Tab + Enter/Space both select it, `aria-pressed` tracks state. The main monitor gets a thin accent bar along its top edge (the "menu bar lives here" cue, same idea macOS's own Displays pane uses); selection is a separate accent ring, so the two don't read as the same thing when a diagram has one monitor that's both main and selected.
