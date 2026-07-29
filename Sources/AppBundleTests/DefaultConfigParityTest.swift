@testable import AppBundle
import XCTest

/// The default config exists twice, and both copies are load-bearing:
///
/// * `resources/default-config.toml` is what `build-release.sh` and `build-debug-app.sh` copy into
///   `Contents/Resources/`, so it is what a user actually gets on a fresh install.
/// * `docs/config-examples/default-config.toml` is what `Config.getDefaultConfigUrlFromProject`
///   reads for builds that are not app bundles (unit tests, a plain `swift build`), and it is the
///   copy the README links for someone who wants to read the defaults without installing anything.
///
/// Nothing in the build makes one follow the other. Editing either alone would mean the shipped
/// defaults and the documented defaults silently disagree, which is the kind of divergence nobody
/// notices until a bug report quotes a line that does not exist in their file.
///
/// A symlink would also solve it, but the Xcode resource copy phase does not reliably preserve one
/// into the bundle, so the guarantee is asserted here instead.
final class DefaultConfigParityTest: XCTestCase {
    func testShippedAndDocumentedDefaultConfigsAreIdentical() throws {
        let shipped = projectRoot.appending(path: "resources/default-config.toml")
        let documented = projectRoot.appending(path: "docs/config-examples/default-config.toml")

        let a = try String(contentsOf: shipped, encoding: .utf8)
        let b = try String(contentsOf: documented, encoding: .utf8)

        guard a != b else { return }

        // Report the first differing line rather than dumping two 100-line files at the reader.
        let aLines = a.split(separator: "\n", omittingEmptySubsequences: false)
        let bLines = b.split(separator: "\n", omittingEmptySubsequences: false)
        let firstDiff = zip(aLines, bLines).enumerated().first { $0.element.0 != $0.element.1 }
        let detail: String = if let firstDiff {
            """
            first difference at line \(firstDiff.offset + 1):
              resources/            \(firstDiff.element.0)
              docs/config-examples/ \(firstDiff.element.1)
            """
        } else {
            "same prefix, different length: \(aLines.count) vs \(bLines.count) lines"
        }
        XCTFail(
            """
            resources/default-config.toml and docs/config-examples/default-config.toml have diverged.
            The first is what ships inside the .app; the second is what the docs show and what tests
            read. Copy one over the other.
            \(detail)
            """,
        )
    }
}
