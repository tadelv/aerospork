#!/bin/bash
cd "$(dirname "$0")/.."
source ./script/setup.sh

if ! test -z "$(git status --porcelain)"; then
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo !!! Uncommitted files detected !!!
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    git diff | sed 's/^/    /'
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo !!! Uncommitted files detected !!!
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Was `exit 0`, which made this a warning pretending to be a guard: the release build then ran
    # `git checkout .` and destroyed exactly the changes reported above. Set
    # AEROSPORK_ALLOW_UNCOMMITTED=1 to opt out deliberately.
    if test -z "${AEROSPORK_ALLOW_UNCOMMITTED:-}"; then
        echo "Commit or stash first, or set AEROSPORK_ALLOW_UNCOMMITTED=1."
        exit 1
    fi
fi
