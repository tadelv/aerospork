#!/bin/bash
cd "$(dirname "$0")/.."
source ./script/setup.sh

./script/check-uncommitted-files.sh

rm -rf ~/Library/Developer/Xcode/DerivedData/aerospork-*
rm -rf ./.xcode-build

rm -rf aerospork.xcodeproj
./generate.sh
