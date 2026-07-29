Use for every boolean setting; AeroSpork settings apply live, so a Toggle never waits for a Save button.

```jsx
<Toggle label="Start AeroSpork at login" checked={startAtLogin} onChange={setStartAtLogin} />
<Toggle label="Show icon in the Dock" checked disabled help="Both icons off would leave no way into Settings" />
```

Label is sentence case and names the effect, not the mechanism. Explanations belong in the section footer (`SettingsHint`), not next to the switch.
