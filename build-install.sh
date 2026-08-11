#!/bin/bash
# build-install.sh — build and install aerospork, release or debug.
#
#   ./build-install.sh                  # release: build + install
#   ./build-install.sh debug            # debug:   build + install
#   ./build-install.sh release --no-build --no-launch
#
# Release installs through the local brew tap (app, CLI, completions, manpages) — see
# install-from-sources.sh. Debug installs to /Applications/AeroSpork-Debug.app, a sibling of
# the release app: separate bundle id (com.wbs.aerospork.debug), separate config
# (~/.aerospork-debug.toml), separate CLI socket, so the two never conflict.
#
# The debug CLI is linked as `aerospork-debug`, never `aerospork`: the two builds bake different
# sockets in, and the release CLI (`aerospork`, installed by brew) would otherwise shadow it on
# PATH — or worse, `aerospork` would silently talk to the wrong app depending on which one is
# running. Run `aerospork-debug …` while the debug app is running.
set -euo pipefail
cd "$(dirname "$0")"

variant=release
rebuild=1
launch=1
while test $# -gt 0; do
    case $1 in
        release|debug) variant=$1; shift ;;
        --no-build) rebuild=0; shift ;;
        --no-launch) launch=0; shift ;;
        *) echo "Unknown option $1" > /dev/stderr; exit 1 ;;
    esac
done

if test "$variant" = release; then
    if test $rebuild -eq 1; then
        ./install-from-sources.sh
    else
        ./install-from-sources.sh --dont-rebuild
    fi
    exit 0
fi

# ---- debug ----
if test $rebuild -eq 1; then
    ./build-debug-app.sh
fi

app=/Applications/AeroSpork-Debug.app
# A running bundle can't be cleanly replaced; quit first (no-op when not running).
if osascript -e 'quit app id "com.wbs.aerospork.debug"' > /dev/null 2>&1; then
    for _ in $(seq 1 10); do
        pgrep -f 'AeroSpork-Debug.app' > /dev/null || break
        sleep 0.5
    done
fi
rm -rf "$app"
cp -R .debug/AeroSpork-Debug.app "$app"
# Debug builds are never notarized; drop any quarantine so Gatekeeper can't kill them.
xattr -dr com.apple.quarantine "$app" 2>/dev/null || true

echo "Installed debug app to $app"
# The debug CLI always gets linked, as `aerospork-debug`. Symlink (not copy) so a rebuild
# of .debug/ is picked up without re-running the install.
mkdir -p ~/bin
ln -sf "$(pwd)/.debug/aerospork" ~/bin/aerospork-debug
if ! echo ":$PATH:" | grep -q ":$HOME/bin:"; then
    echo "NOTE: ~/bin is not on PATH; run the CLI as ~/bin/aerospork-debug or add ~/bin to PATH"
fi
if test $launch -eq 1; then
    open "$app"
fi
