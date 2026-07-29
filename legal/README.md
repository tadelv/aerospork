# LICENSE

AeroSpork is licensed under MIT. See [LICENSE](./LICENSE.txt) for the full license text.

## Attribution

AeroSpork is a fork of [AeroSpace](https://github.com/nikitabobko/AeroSpace) by Nikita Bobko, also
MIT licensed. The copyright notice in [LICENSE.txt](./LICENSE.txt) retains the original author's
copyright alongside the fork's, as MIT requires.

**The upstream name is kept here deliberately.** Everywhere else in this project the product is
called AeroSpork, but attribution has to name the thing it is attributing — renaming AeroSpace in a
copyright notice would misattribute someone else's work, and MIT specifically requires the notice be
retained.

## Bundled dependencies and materials

AeroSpork bundles the following:

**Lucide icons** (ISC). The 41 SVGs in
`.claude/skills/aerospork-design/assets/icons/`, and the same geometry inlined by the design
system's `Icon` component. They are a web-only substitution for SF Symbols, which Apple does not
permit redistributing; the shipping app uses SF Symbols by name and bundles none of these.
See [LICENSE-lucide.txt](./third-party-license/LICENSE-lucide.txt).

**TOMLKit**.
[TOMLKit GitHub link](https://github.com/LebJe/TOMLKit).
[TOMLKit MIT license](./third-party-license/LICENSE-TOMLKIT.txt).
TOMLKit is used as a Swift wrapper around the tomlplusplus C++ API. It is the only third-party
Swift package AeroSpork depends on.

**tomlplusplus**.
[tomlplusplus GitHub link](https://github.com/marzer/tomlplusplus).
[tomlplusplus MIT license](./third-party-license/LICENSE-tomlplusplus.txt).
tomlplusplus is the actual TOML parser, vendored inside TOMLKit and therefore bundled indirectly.

## Dependencies this fork removed

Upstream AeroSpace bundled the following; AeroSpork replaced each with a platform API and no longer
ships any of them. Their licence texts have been removed from `third-party-license/` accordingly —
shipping a licence for code that is not in the binary is misleading.

| Was | Replaced by |
|---|---|
| BlueSocket | POSIX `AF_UNIX` sockets (`Sources/Common/util/UnixSocket.swift`) |
| HotKey | Carbon `RegisterEventHotKey` (`Sources/AppBundle/config/HotkeyBinding.swift`) |
| ISSoundAdditions | CoreAudio (`Sources/AppBundle/util/SystemVolume.swift`) |
| swift-collections | Plain Swift collections |
| ANTLR v4 | Not used — the built-in shell-like language it parsed is gone |
