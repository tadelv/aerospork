#!/bin/bash
# Code-signing identity detection, shared by generate.sh and build-release.sh.
#
# It lives here because both need it and they used to disagree: generate.sh learned to detect a real
# identity while build-release.sh kept defaulting to `aerospork-codesign-certificate`, a placeholder
# name that has never existed in any keychain. A plain `./build-release.sh` therefore built the whole
# universal binary and the .app, then died at the CLI `codesign` step with "no identity found".

# Prefer a Developer ID Application cert -- the only kind notarization accepts. Fall back to Apple
# Development so a local release build still produces a signed bundle you can run.
#
# `security` prints e.g.  1) ABC123... "Developer ID Application: Name (TEAMID)"
default_signing_identity() {
    local identities found
    identities=$(security find-identity -v -p codesigning 2>/dev/null)
    found=$(sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' <<< "$identities" | head -1)
    # `head` succeeds on empty input, so test the STRING, not the exit status.
    if test -n "$found"; then echo "$found"; return; fi
    sed -n 's/.*"\(Apple Development:[^"]*\)".*/\1/p' <<< "$identities" | head -1
}

# "Apple Distribution" is deliberately NOT used as a fallback above, and this exists to say why.
#
# It is an easy cert to create by mistake: it sits directly above "Developer ID Application" in
# Xcode's Manage Certificates "+" menu, and its name sounds like the one you want for distributing
# something. It is for the **Mac App Store / TestFlight** only. The notary service does not accept
# it, and Gatekeeper will not clear a directly-downloaded app signed with it — which is exactly how
# this project ships (zip + Homebrew cask). Signing with it produces a build that looks correctly
# signed and is still blocked on every machine but the one that built it.
warn_if_only_app_store_distribution() {
    local identities
    identities=$(security find-identity -v -p codesigning 2>/dev/null)
    grep -q '"Developer ID Application:' <<< "$identities" && return 0
    grep -q '"Apple Distribution:' <<< "$identities" || return 0
    echo "!!! Found an 'Apple Distribution' certificate but no 'Developer ID Application'." > /dev/stderr
    echo "!!! Apple Distribution is a Mac App Store cert; it cannot be notarized and Gatekeeper" > /dev/stderr
    echo "!!! will block a downloaded build signed with it. Create a Developer ID Application cert" > /dev/stderr
    echo "!!! instead (Xcode > Settings > Accounts > Manage Certificates > +). That entry is hidden" > /dev/stderr
    echo "!!! unless the signed-in Apple ID is the team's Account Holder." > /dev/stderr
}

# Automatic signing REQUIRES a team; project.yml interpolates this.
#
# Read it from the certificate's OU field, NOT from the "(XXXXXXXXXX)" in the identity's common
# name. Those agree for a Developer ID cert but NOT for an Apple Development one, where the
# parenthetical is the App Store Connect API key id that created it, which is NOT the team the
# bundles are signed with. Guessing from the name produces a team that looks plausible and fails at
# signing time.
default_development_team() {
    local name="$1"
    test -n "$name" || return 0
    security find-certificate -c "$name" -p 2>/dev/null \
        | openssl x509 -noout -subject 2>/dev/null \
        | tr ',' '\n' | sed -n 's/.*OU=\([A-Z0-9]\{10\}\).*/\1/p' | head -1
}
