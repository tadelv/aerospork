import React from 'react';
import { Icon } from '../icons/Icon.jsx';

/* Placeholder app-icon tile: a glyph on a rounded-square plate, in the same squircle convention
   as the product's own icon (tokens/radius.css --icon-corner-ratio). Stands in for a real macOS
   app icon in this mock ONLY — every glyph below is a generic pictogram (an envelope, a compass,
   a folder…), not traced from any real app's actual icon art. Bundling real app icons in a public
   design-system repo is both a trademark problem and pointless duplication of art nobody here owns.

   DO NOT carry this component's *approach* into the real Swift app. The shipping Settings window
   should bundle no icon assets at all — it should resolve each app's REAL, currently-installed
   icon at runtime:
     let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appId)
     let icon = url.map { NSWorkspace.shared.icon(forFile: $0.path) }
   That is not a legal workaround, it is also simply correct: it shows the user's own icon (right
   theme, right version), works for any app ID including ones nobody thought to hardcode, and it
   stays right if an app's icon ever changes. SAMPLE_APPS below exists only so this mock has
   *something* recognizable to render; it is deliberately small and must not grow into a "real app
   icon library" — that instinct is exactly the thing NSWorkspace makes unnecessary. */
export const SAMPLE_APPS = [
  { id: 'com.apple.mail', name: 'Mail', glyph: 'envelope', tint: ['#67b6ff', '#0a6cf0'] },
  { id: 'com.apple.Safari', name: 'Safari', glyph: 'safari', tint: ['#6fe0ff', '#0077c2'] },
  { id: 'com.mitchellh.ghostty', name: 'Ghostty', glyph: 'terminal', tint: ['#5a5a60', '#232326'] },
  { id: 'com.spotify.client', name: 'Spotify', glyph: 'music.note', tint: ['#6bef95', '#159c46'] },
  { id: 'com.tinyspeck.slackmacgap', name: 'Slack', glyph: 'message', tint: ['#d3aeff', '#7c3aed'] },
  { id: 'com.apple.finder', name: 'Finder', glyph: 'folder', tint: ['#8fd9ff', '#1f6fe0'] },
  { id: 'com.apple.systempreferences', name: 'System Settings', glyph: 'gearshape', tint: ['#b8b8bd', '#6e6e73'] },
];

const BY_ID = Object.fromEntries(SAMPLE_APPS.map((a) => [a.id, a]));

/** Best-effort display name for a bundle ID: SAMPLE_APPS, else its last path component,
    title-cased — the same fallback a hand-typed app ID needs everywhere this shows a name. */
export function appDisplayName(appId) {
  if (!appId) return 'Any app';
  const known = BY_ID[appId];
  if (known) return known.name;
  const last = appId.split('.').filter(Boolean).pop() || appId;
  return last.charAt(0).toUpperCase() + last.slice(1);
}

// ponytail: five hand-picked tints, chosen by a stable hash of the app ID so an unrecognized app
// keeps the same color across renders instead of reshuffling — not a real color-quantization
// algorithm, which would be pointless for a fallback nobody is meant to stare at.
const FALLBACK_TINTS = [
  ['#ffc06b', '#e0821e'], ['#9fd6ff', '#3f7fd4'], ['#ddb8ff', '#8b5cf6'],
  ['#ffb0c2', '#e0446a'], ['#c3f0a4', '#3fa34d'],
];
function hashTint(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
  return FALLBACK_TINTS[h % FALLBACK_TINTS.length];
}

/** A rounded-square glyph tile standing in for a real app icon.
    - Known sample app (SAMPLE_APPS): its glyph, on its tint.
    - Unknown but non-empty appId (hand-typed, not in the sample set): a monogram of its
      resolved name, on a tint hashed from the id — stable, not random, across re-renders.
    - No appId at all ('' / null / undefined — the "any app" matcher): a neutral plate with a
      generic window glyph, never a monogram, so it can't be mistaken for a specific unknown app. */
export function AppIcon({ appId, size = 32, style }) {
  const known = appId ? BY_ID[appId] : null;
  const customTyped = !!appId && !known;
  const [from, to] = known ? known.tint : customTyped ? hashTint(appId) : ['#c7c7cc', '#98989d'];
  const radius = Math.round(size * 0.225); // tokens/radius.css --icon-corner-ratio
  return (
    <div aria-hidden="true" style={{
      width: size, height: size, flex: '0 0 auto', borderRadius: radius, position: 'relative',
      background: `linear-gradient(180deg, ${from}, ${to})`, overflow: 'hidden',
      display: 'grid', placeItems: 'center',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,.32), inset 0 -1px 1px rgba(0,0,0,.22), 0 0.5px 1.5px rgba(0,0,0,.22)',
      ...style,
    }}>
      {known
        ? <Icon sf={known.glyph} size={Math.round(size * 0.56)} style={{ color: 'rgba(255,255,255,.95)' }} />
        : customTyped
          ? <span style={{ font: `var(--weight-semibold) ${Math.round(size * 0.46)}px/1 var(--font-rounded)`, color: 'rgba(255,255,255,.95)' }}>
              {appDisplayName(appId).charAt(0).toUpperCase()}
            </span>
          : <Icon sf="macwindow" size={Math.round(size * 0.5)} style={{ color: 'rgba(255,255,255,.85)' }} />}
    </div>
  );
}
