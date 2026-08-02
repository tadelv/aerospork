import React from 'react';

// Row height in px for the gutter/pre/textarea to share. --text-default is 13px and the editor's
// own line-height is the unitless multiplier 1.45 (both from tokens/typography.css); this is a
// literal rather than a getComputedStyle read so gutter rows line up without a measuring effect.
// ponytail: bump this if --text-default or the 1.45 line-height ever change.
const LINE_HEIGHT = 1.45;
const FONT_PX = 13;
const ROW_PX = FONT_PX * LINE_HEIGHT;

// Tightened vs. the proposal's own sketch (`^\s*[\[\[]?[^\[\]=]+[\]\]]?\s*$`, proposal-rawtoml.md
// §2.2), which — read literally — also matches plain non-bracket lines since the brackets are each
// optional. Requiring the brackets is what "is this a header line" actually means.
const HEADER_RE = /^\[{1,2}[^\[\]=]+\]{1,2}$/;
const KEY_RE = /^(\s*)([A-Za-z0-9_.\-"]+)(\s*=)/;

function isHeaderLine(code) {
  return HEADER_RE.test(code.trim());
}

// ponytail: naive — doesn't skip a `#` inside a quoted string (`key = "a # not a comment"`).
// Called out as an acknowledged mockup simplification in proposal-rawtoml.md §2.2; the real
// tokenizer needs to walk string spans before looking for `#`.
function splitComment(line) {
  const i = line.indexOf('#');
  return i === -1 ? [line, ''] : [line.slice(0, i), line.slice(i)];
}

// Three tiers, not four — structure (headers), the thing you'd search for (keys), and comments get
// a span; everything else (strings/numbers/booleans/dates/punctuation/the `=` itself) inherits the
// <pre>'s own secondary-opacity color. Deliberately not a per-value-type rainbow scheme — see
// proposal-rawtoml.md §1/§2.2 for why.
const TOKEN_STYLE = {
  header: { color: 'var(--accent)', fontWeight: 'var(--weight-medium)' },
  comment: { color: 'var(--label-tertiary)', fontWeight: 'var(--weight-regular)' },
  key: { color: 'var(--label)', fontWeight: 'var(--weight-medium)' },
};

function renderLine(line, headerLineSet, lineNum) {
  const [code, comment] = splitComment(line);
  const nodes = [];
  if (headerLineSet.has(lineNum)) {
    nodes.push(<span key="h" style={TOKEN_STYLE.header}>{code}</span>);
  } else {
    const m = code.match(KEY_RE);
    if (m) {
      nodes.push(m[1]);
      nodes.push(<span key="k" style={TOKEN_STYLE.key}>{m[2]}</span>);
      nodes.push(code.slice(m[1].length + m[2].length));
    } else if (code) {
      nodes.push(code);
    }
  }
  if (comment) nodes.push(<span key="c" style={TOKEN_STYLE.comment}>{comment}</span>);
  return nodes;
}

/* Editable text that is code, not prose: 13px monospaced (matches every other monospaced element
   in the window — key/command rows, the version string), 10/12px container inset, on
   textBackgroundColor. In the app this is an NSTextView with every macOS text substitution
   turned off — smart quotes would turn a valid TOML string into an invalid one.

   Also owns (proposal-rawtoml.md §2.1-§2.3): a line-number gutter, restrained 3-tier TOML
   highlighting, and inline error/warning gutter markers. Built via the highlighted-<pre>-under-a-
   transparent-<textarea> overlay technique — the textarea stays the single source of truth for
   editing/selection/caret; the <pre> underneath only paints. The outer element auto-grows to its
   content and owns vertical scroll (no nested scrollbars), which is also what keeps the gutter in
   lockstep with the text for free. Search-in-editor (⌘F) is not part of this component — see the
   comment in RawTomlTab.jsx.

   `ref` exposes one imperative method, `scrollToLine(line)`, for callers that need to jump the
   caret to a known line (a picked "Sections…" entry, a clicked error) — the React equivalent of
   the real NSTextView's `scrollRangeToVisible`/`setSelectedRange`, which only the view that owns
   the text storage can drive. */
export const CodeEditor = React.forwardRef(function CodeEditor({
  value = '', onChange, readOnly = false,
  errorLine = null, warningLines = [], onCursorMove, sectionHeaders,
  style,
}, ref) {
  const taRef = React.useRef(null);
  const scrollRef = React.useRef(null);
  const [height, setHeight] = React.useState(120);
  const lines = React.useMemo(() => value.split('\n'), [value]);

  // Section headers are derived by the tab from the same buffer (so the Sections… menu and this
  // highlighting can't disagree) and passed down; fall back to our own scan so the component still
  // works standalone.
  const headerLineSet = React.useMemo(() => {
    if (sectionHeaders) return new Set(sectionHeaders.map((h) => h.line));
    const set = new Set();
    lines.forEach((line, i) => { if (isHeaderLine(splitComment(line)[0])) set.add(i + 1); });
    return set;
  }, [sectionHeaders, lines]);

  React.useLayoutEffect(() => {
    const ta = taRef.current;
    if (!ta) return;
    ta.style.height = 'auto'; // release the explicit height so scrollHeight reflects real content
    setHeight(Math.max(120, ta.scrollHeight));
  }, [value]);

  React.useImperativeHandle(ref, () => ({
    scrollToLine(line) {
      const ta = taRef.current;
      if (!ta) return;
      const clamped = Math.max(1, Math.min(line, lines.length));
      const pos = lines.slice(0, clamped - 1).reduce((n, l) => n + l.length + 1, 0);
      ta.focus();
      ta.setSelectionRange(pos, pos);
      if (onCursorMove) onCursorMove(clamped, 1);
      const rowTop = (clamped - 1) * ROW_PX;
      if (scrollRef.current) scrollRef.current.scrollTo({ top: Math.max(0, rowTop - ROW_PX * 3), behavior: 'smooth' });
    },
  }), [lines, onCursorMove]);

  const reportCursor = (e) => {
    if (!onCursorMove) return;
    const before = value.slice(0, e.target.selectionStart).split('\n');
    onCursorMove(before.length, before[before.length - 1].length + 1);
  };

  const digits = Math.max(3, String(lines.length).length);
  // Shared so the <pre> and <textarea> glyphs land exactly on top of one another.
  const fontStack = {
    fontFamily: 'var(--font-mono)', fontSize: 'var(--text-default)', lineHeight: LINE_HEIGHT,
    tabSize: 4, padding: '12px 10px', boxSizing: 'border-box',
    // ponytail: wrapping stays on (unchanged from the plain-textarea original), so the gutter is a
    // naive one-row-per-source-line numbering rather than wrap-fragment-aware — a long wrapped
    // line's continuation rows won't get their own gutter row. Real fix is an NSRulerView driven by
    // NSLayoutManager's line fragments (see proposal-rawtoml.md §4); not worth it for a mockup of
    // config files that are typically short `key = value` lines.
    whiteSpace: 'pre-wrap', wordBreak: 'break-word', overflowWrap: 'break-word',
  };

  return (
    <div ref={scrollRef} style={{
      flex: 1, minHeight: 0, display: 'flex', overflowY: 'auto', background: 'var(--text-bg)', ...style,
    }}>
      <div style={{
        flex: '0 0 auto', width: `calc(${digits}ch + 22px)`, background: 'var(--fill-subtle)',
        borderRight: '1px solid var(--separator)', paddingTop: 12, paddingBottom: 12, boxSizing: 'border-box',
      }}>
        {lines.map((_, i) => {
          const n = i + 1;
          const kind = n === errorLine ? 'error' : warningLines.includes(n) ? 'warning' : null;
          const color = kind === 'error' ? 'var(--status-error)' : kind === 'warning' ? 'var(--status-warning)' : 'var(--label-tertiary)';
          return (
            <div key={n} style={{
              position: 'relative', lineHeight: ROW_PX + 'px', fontSize: 'var(--text-subheadline)',
              fontFamily: 'var(--font-system)', color, textAlign: 'right', paddingRight: 8, paddingLeft: 6,
            }}>
              {kind && <span style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: 3, background: color }} />}
              {n}
            </div>
          );
        })}
      </div>
      <div style={{ flex: 1, minWidth: 0, position: 'relative', height }}>
        <pre style={{
          margin: 0, position: 'absolute', inset: 0, pointerEvents: 'none', color: 'var(--label-secondary)',
          ...fontStack,
        }}>
          {lines.map((line, i) => (
            <React.Fragment key={i}>{i > 0 && '\n'}{renderLine(line, headerLineSet, i + 1)}</React.Fragment>
          ))}
        </pre>
        <textarea
          ref={taRef} value={value} readOnly={readOnly} spellCheck={false}
          onChange={(e) => { onChange && onChange(e.target.value); reportCursor(e); }}
          onSelect={reportCursor} onClick={reportCursor} onKeyUp={reportCursor}
          style={{
            position: 'absolute', top: 0, left: 0, width: '100%', height, resize: 'none',
            border: 'none', outline: 'none', background: 'transparent',
            color: 'transparent', caretColor: 'var(--label)', ...fontStack,
          }}
        />
      </div>
    </div>
  );
});
