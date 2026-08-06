@testable import AppBundle
import Common
import Foundation
import XCTest

/// Every TOML example in `README.md` must parse.
///
/// The README previously taught the older config spelling (`[mode.main.binding]`,
/// `[workspace-to-monitor-force-assignment]`) while the shipped default config used the current one
/// — so the first thing a new user copied was not what the app documents anywhere else. Examples in
/// a README are code; nothing was checking them.
@MainActor
final class ReadmeExamplesTest: XCTestCase {
  /// Fenced ```toml blocks, in order.
  private func tomlBlocks(in markdown: String) -> [String] {
    var blocks: [String] = []
    var current: [String] = []
    var inside = false
    for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed == "```toml" { inside = true
        current = []
        continue }
      if inside, trimmed == "```" { inside = false
        blocks.append(current.joined(separator: "\n"))
        continue }
      if inside { current.append(String(line)) }
    }
    return blocks
  }

  func testEveryTomlExampleParses() throws {
    let readme = try String(contentsOf: projectRoot.appending(path: "README.md"), encoding: .utf8)
    let blocks = tomlBlocks(in: readme)
    XCTAssertFalse(blocks.isEmpty, "no ```toml blocks found -- the extractor is broken, not the README")

    for (i, block) in blocks.enumerated() {
      switch parseConfig(block) {
        case .success: continue
        case .failure(let errors):
          XCTFail("README TOML example #\(i + 1) does not parse:\n\(block)\n\n\(errors.descriptions)")
      }
    }
  }

  /// The README should teach the same schema the app ships as its default, not a legacy spelling
  /// that merely still parses.
  func testExamplesUseTheCurrentSchema() throws {
    let readme = try String(contentsOf: projectRoot.appending(path: "README.md"), encoding: .utf8)
    let toml = tomlBlocks(in: readme).joined(separator: "\n")
    XCTAssertTrue(toml.contains("mod ="), "the README should show the generated-keymap schema")
    XCTAssertFalse(
      toml.contains("[mode.main.binding]"),
      "the README teaches the superseded binding spelling; the shipped default uses [keys]"
    )
    XCTAssertFalse(
      toml.contains("workspace-to-monitor-force-assignment"),
      "the README teaches the superseded monitor spelling; the shipped default uses [monitors]"
    )
  }
}
