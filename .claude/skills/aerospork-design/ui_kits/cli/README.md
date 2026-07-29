# UI kit — CLI

The `aerospork` client is the product's primary surface: 36 commands, man pages, shell completion.
This kit shows what that looks like in a terminal, for docs and marketing shots.

Conventions this recreation follows, from `docs/`:

- Commands succeed silently — `aerospork focus left` prints nothing.
- Output is columnar and interpolation-driven: the default `list-monitors` format is
  `%{monitor-id}%{right-padding} | %{monitor-name}`.
- `--format`, `--json` and `--count` are the shapes of every list command.
- Diagnostics are one line and name the file or the number, never a stack trace.

**Illustrative:** monitor names, UUIDs and version strings are fabricated sample data; the *shapes*
come from `docs/aerospork-list-monitors.adoc` and the README's Troubleshooting section. Do not quote
these strings as real output.
