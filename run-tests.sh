#!/bin/bash
cd "$(dirname "$0")"
source ./script/setup.sh

./build-debug.sh
./run-swift-test.sh

./.debug/aerospork -h > /dev/null
./.debug/aerospork --help > /dev/null
# The version string comes from generate.sh's default (1.0.0), not build-release.sh's
# (0.0.0-SNAPSHOT). Asserting the latter made this script fail for everyone, which mattered because
# script/publish-release.sh runs run-tests.sh first -- so the whole publish path was gated behind a
# guaranteed failure. Assert the shape, not a hardcoded number.
# Case-insensitive: the product is written "AeroSpork" in prose, while the command, bundle and
# config file stay lowercase. This assertion is about the SHAPE of the version line, not its
# styling -- pinning the case made a branding fix fail the build.
./.debug/aerospork -v | grep -qiE '^aerospork CLI client version: [0-9]+\.[0-9]+\.[0-9]+ '
./.debug/aerospork --version | grep -qiE '^aerospork CLI client version: [0-9]+\.[0-9]+\.[0-9]+ '

./format.sh
./generate.sh --all
./script/check-uncommitted-files.sh

echo
echo "All tests have passed successfully"
