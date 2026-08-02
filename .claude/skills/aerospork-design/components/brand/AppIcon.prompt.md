Original, generic glyph-in-rounded-square placeholders standing in for real macOS app icons — never trace or bundle a real app's actual icon art (trademark, and pointless once you have `NSWorkspace`). Use as the visual anchor for anything keyed on an app ID: a rule list, an app picker. Unknown app IDs still render (a monogram fallback), so it degrades gracefully for a hand-typed bundle ID; an empty ID renders a neutral "any app" glyph instead of a blank tile.

~~~jsx
<AppIcon appId="com.apple.mail" size={32} />
<AppIcon appId="org.mozilla.firefox" size={32} /> {/* not in the sample set → "F" monogram */}
<AppIcon appId="" size={32} /> {/* the "any app" matcher → generic window glyph */}
~~~

In the real Swift app, ship no bundled icon assets — resolve `NSWorkspace.shared.icon(forFile:)` via `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` so the row always shows the user's actual, currently-installed icon.
