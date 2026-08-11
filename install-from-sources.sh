#!/bin/bash
cd "$(dirname "$0")"
source ./script/setup.sh

rebuild=1
while test $# -gt 0; do
    case $1 in
        --dont-rebuild) rebuild=0; shift ;;
        *) echo "Unknown option $1"; exit 1 ;;
    esac
done

if test $rebuild == 1; then
    ./build-release.sh
fi

brew list aerospork-dev > /dev/null 2>&1 && brew uninstall aerospork-dev
brew list aerospork > /dev/null 2>&1 && brew uninstall aerospork

# Override HOMEBREW_CACHE. Otherwise, homebrew refuses to "redownload" the snapshot file
# Maybe there is a better way, I don't know
rm -rf /tmp/aerospork-from-sources-brew-cache

# Newer Homebrew (4.x+) refuses to install a cask from a bare .rb path:
#   Error: Homebrew requires casks to be in a tap, rejecting: ./.release/aerospork-dev.rb
# so the generated cask is installed from a local tap instead. `local/` is a conventional
# org name for a personal, never-published tap; it keeps the cask's full install behavior
# (app + CLI symlink + completions + manpages + zap) without touching any public tap.
tap=local/aerospork
# tap dirs are flat: Taps/<org>/homebrew-<repo> -- never Taps/<org>/<repo>/...
tap_dir="$(brew --repository)/Library/Taps/${tap%/*}/homebrew-${tap#*/}"
if test ! -d "$tap_dir"; then
    brew tap-new "$tap" > /dev/null
fi
mkdir -p "$tap_dir/Casks"
cp .release/aerospork-dev.rb "$tap_dir/Casks/"

env HOMEBREW_CACHE=/tmp/aerospork-from-sources-brew-cache \
    brew install --cask "$tap/aerospork-dev"

# A dev/SNAPSHOT build is signed but NOT notarized (no AEROSPORK_NOTARY_PROFILE), so while the
# quarantine attribute is present Gatekeeper rejects it -- the "aerospork cannot be opened"
# dialog, and a silent SIGKILL for the CLI. A notarized+stapled build passes spctl and is left
# alone. This is the same quarantine-strip the cask used to do pre-notarization, scoped to
# installs that actually need it.
app=/Applications/AeroSpork.app
if ! spctl -a -vv "$app" > /dev/null 2>&1; then
    echo "Not notarized (dev build) -- removing quarantine so the app launches locally."
    echo "For a build that passes Gatekeeper anywhere, set up notarization (see build-release.sh)."
    xattr -dr com.apple.quarantine "$app"
fi
