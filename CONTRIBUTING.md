# Contributing

## Before you start

Open an issue first for anything beyond a bug fix. Feature parity with
[AeroSpace](https://github.com/nikitabobko/AeroSpace) is not a goal here, so a change that adds
surface area needs a reason beyond "upstream has it".

## Setup

`dev-docs/development.md` is the full setup, including the code-signing certificate a release build
needs. The short version:

```bash
./build-debug.sh     # SwiftPM debug build into .debug/ (uses ~/.aerospork-debug.toml)
./run-tests.sh       # the gate: build, both test targets, CLI checks, format, lint, generated files
```

Debug builds read `~/.aerospork-debug.toml`, so you can develop without touching the config you use
day to day.

## The gate

`./run-tests.sh` is what CI runs. It must pass before a pull request can be reviewed. It also fails
on an unclean working tree, because several checked-in files are generated (`./generate.sh`) and
drift between the source and the generated copy is a real bug rather than noise.

`./format.sh` runs SwiftFormat and SwiftLint. Run it before committing; CI checks formatting is
already clean rather than fixing it for you.

## Things the tests enforce, and why

These are easy to trip over, so they are worth knowing before review points them out:

- **Shared settings controls live in `Sources/AppBundle/ui/SettingsChrome.swift`.** A tab uses what
  is there rather than adding a local copy, and status symbols come from `StatusLabel.Kind` rather
  than string literals. `UIChromeConsistencyTest`.
- **The config writer must not rewrite a section the user did not edit.** The view model is a lossy
  projection of the config, so re-serializing an untouched section destroys anything the UI cannot
  express. `testWriterNoOpSaveIsByteIdentical`.
- **No unconditional `print` in hot paths**, and `debugLog` must stay `@autoclosure` so its message
  is never built when the gate is off. `PerfInvariantsTest`.
- **The two copies of the default config must stay identical.** `DefaultConfigParityTest`.
- **Do not put measured performance claims in docs without a measurement behind them.**
  `dev-docs/performance.md` explains which numbers exist and which the available benchmark could not
  resolve.

## Documentation

Docs are AsciiDoc under `docs/`, and `docs/aerospork-*.adoc` doubles as the man pages and the CLI
help text. Adding a command means adding its page; see the checklist in `dev-docs/architecture.md`.
Run `./build-docs.sh` and check the result in `.site/` and `.man/`.

Prose style: neutral and utilitarian. Explain the consequence rather than restating the control, and
prefer a colon or a full stop to an em dash.

## Reporting a bug

Include the output of:

```bash
aerospork --version
aerospork config --config-path
log show --last 15m --predicate 'subsystem == "com.wbs.aerospork"' --style compact
```

For a layout or focus problem, `AEROSPORK_DEBUG_LOG=1` adds a per-refresh trace. It goes to stderr,
not the unified log, so run the binary directly to capture it. `docs/guide.adoc` has the full
recipe under *Troubleshooting and bug reports*.
