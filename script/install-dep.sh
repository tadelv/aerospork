#!/bin/bash
cd "$(dirname "$0")/.."
source ./script/setup.sh

all=0
complgen=0
swiftlint=0
swiftformat=0
xcodegen=0
bundler=0
while test $# -gt 0; do
    case $1 in
        --complgen) complgen=1; shift ;;
        --swiftlint) swiftlint=1; shift ;;
        --xcodegen) xcodegen=1; shift ;;
        --swiftformat) swiftformat=1; shift ;;
        --bundler) bundler=1; shift ;;
        --all) all=1; shift ;;
        *) echo "Unknown option $1"; exit 1 ;;
    esac
done

get-marker() { echo ".deps/markers/$1/$(echo "$@" | shasum | awk '{print $1}').marker"; }

create-marker() {
    dir="$(dirname "$1")"
    rm -rf "$dir" && mkdir -p "$dir"
    touch "$1"
}

if test $all == 1 || test $bundler == 1; then
    # Checked before the marker, which only guards `bundler install` -- build-docs.sh runs
    # `bundler exec asciidoctor` on every build, marker or not.
    #
    # A Ruby upgrade can leave a gemspec in <gem-home>/specifications whose gem directory is gone
    # (seen going 3.4 -> 4.0: the kept bundler-2.6.9.gemspec, the removed gems/bundler-2.6.9/).
    # The binstub then activates a spec with no files and dies with a RubyGems LoadError naming an
    # absolute path, which says nothing about the machine being the problem.
    #
    # The system bundler is the ONLY Ruby this build needs: BUNDLE_PATH in .bundle/config pulls
    # everything else (bundler itself included) into ./.deps, so it works on any Ruby >= 3.0.
    if ! bundler --version > /dev/null 2>&1; then
        echo "bundler is not usable: '$(command -v bundler)' failed." > /dev/stderr
        echo "A Ruby upgrade can leave a stale gemspec in <gem-home>/specifications/ whose gem" > /dev/stderr
        echo "directory no longer exists. Remove that gemspec, or use rbenv with .ruby-version" > /dev/stderr
        echo "(dev-docs/development.md section 1.4)." > /dev/stderr
        exit 1
    fi
    marker=$(get-marker bundler "$(cat ./Gemfile)" "$(cat ./.bundle/*)")
    if ! test -f "$marker"; then
        bundler install
        create-marker "$marker"
    fi
fi

if test $all == 1 || test $complgen == 1; then
    # https://github.com/adaszko/complgen/releases
    complgen_rev=cacb3970eb
    marker=$(get-marker complgen $complgen_rev)
    if ! test -f "$marker"; then
        cargo install --git https://github.com/adaszko/complgen --rev $complgen_rev --root ./.deps/cargo-root
        create-marker "$marker"
    fi
fi

lazy-download-zip-and-link-bin() {
    artifact_name=$1
    link=$2
    sha=$3
    path_inside_zip=$4

    root_path=".deps/$artifact_name"
    marker_path=$(get-marker "$artifact_name" "$@")

    if ! test -f "$marker_path"; then
        root_dist_path="$root_path/dist"
        zip_name="zip.zip"
        zip_path="$root_dist_path/$zip_name"

        rm -rf "$root_path" && mkdir -p "$root_dist_path"
        curl -L "$link" -o "$zip_path"
        diff --color <(echo "$sha") <(shasum -a 256 "$zip_path")
        (cd "$root_dist_path" && unzip "$zip_name")
        (cd "$root_path" && ln -s "./dist/$path_inside_zip" "$artifact_name")

        create-marker "$marker_path"
    fi
}

if test $all == 1 || test $swiftlint == 1; then
    # https://github.com/realm/SwiftLint/releases
    swiftlint_version=0.65.0
    lazy-download-zip-and-link-bin \
        swiftlint \
        https://github.com/realm/SwiftLint/releases/download/$swiftlint_version/SwiftLintBinary.artifactbundle.zip \
        'eb333bd76dfb5f46d21fdf3615fe39bb938956ca0b8e94c241c4b2db6e696b90  .deps/swiftlint/dist/zip.zip' \
        SwiftLintBinary.artifactbundle/macos/swiftlint
fi

if test $all == 1 || test $xcodegen == 1; then
    # https://github.com/yonaskolb/XcodeGen/releases
    xcodegen_version=2.46.0
    lazy-download-zip-and-link-bin \
        xcodegen \
        https://github.com/yonaskolb/XcodeGen/releases/download/$xcodegen_version/xcodegen.artifactbundle.zip \
        'ef6d0a23bfb7393387f98e321ffd78a487231172e2e78c48d3c26275c263fd0c  .deps/xcodegen/dist/zip.zip' \
        xcodegen.artifactbundle/xcodegen-$xcodegen_version-macosx/bin/xcodegen
fi

if test $all == 1 || test $swiftformat == 1; then
    # https://github.com/nicklockwood/SwiftFormat/releases
    swiftformat_version=0.62.1
    lazy-download-zip-and-link-bin \
        swiftformat \
        https://github.com/nicklockwood/SwiftFormat/releases/download/$swiftformat_version/swiftformat.artifactbundle.zip \
        '6595f3121e657438a24dabd9f8fecb648d3f362e5106df0968f734f5863fe404  .deps/swiftformat/dist/zip.zip' \
        swiftformat.artifactbundle/swiftformat-$swiftformat_version-macos/bin/swiftformat
fi
