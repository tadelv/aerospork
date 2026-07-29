---
name: Bug report
about: Something behaves differently from how it is documented
labels: bug
---

**What happened, and what you expected instead**

**Steps to reproduce**

**Version and config path**

```
$ aerospork --version

$ aerospork config --config-path

```

A config path inside the `.app` bundle means no user config is loaded, either because you have none
or because yours failed to parse. `aerospork reload-config --dry-run` says which.

**Log**

```
$ log show --last 15m --predicate 'subsystem == "com.wbs.aerospork"' --style compact

```

Use `com.wbs.aerospork.debug` for a debug build. For a layout or focus problem, run the binary
directly with `AEROSPORK_DEBUG_LOG=1` and attach the stderr trace; those records do not reach the
unified log.

**Monitors**, if the problem involves more than one:

```
$ aerospork list-monitors --format '%{monitor-fingerprint}'

```

Redact the UUIDs if you would rather not publish them. They identify specific hardware.
