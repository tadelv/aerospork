@testable import AppBundle
import AppKit
import Common
import Foundation
import XCTest

/// The UI is not headless-renderable, so these cover the parts of it that are actually logic:
/// the key-notation codec behind the shortcut recorder, tray item identity, and the deployment
/// floor that decides whether a control renders at all.
@MainActor
final class UISettingsTest: XCTestCase {
    // MARK: - Key recorder

    /// Every Swift file of the settings UI. Asserts non-empty, so a wrong path cannot make the
    /// source-text invariants below pass vacuously.
    private func uiSources() throws -> [URL] {
        let directory = projectRoot.appending(path: "Sources/AppBundle/ui")
        let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" } ?? []
        XCTAssertFalse(files.isEmpty, "no UI sources found at \(directory.path)")
        return files
    }

    private func keyEvent(_ chars: String, keyCode: UInt16, _ flags: NSEvent.ModifierFlags = []) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: flags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: chars,
            charactersIgnoringModifiers: chars,
            isARepeat: false,
            keyCode: keyCode,
        ).orDie("NSEvent.keyEvent returned nil")
    }

    /// Modifier order is not cosmetic: it is the string written into the config, and `ctrl-alt-h`
    /// and `alt-ctrl-h` are two different TOML keys for the same physical shortcut.
    func testRecorderBuildsNotationInCanonicalModifierOrder() {
        assertEquals(KeyNotation.from(event: keyEvent("h", keyCode: 4, [.option, .shift])), "alt-shift-h")
        assertEquals(KeyNotation.from(event: keyEvent("h", keyCode: 4, [.command, .control])), "ctrl-cmd-h")
        assertEquals(KeyNotation.from(event: keyEvent("1", keyCode: 18, [.option])), "alt-1")
    }

    /// Keys with no useful `charactersIgnoringModifiers` have to come from the key code, or the
    /// recorder silently records nothing when you press Tab or an arrow.
    func testRecorderNamesKeysThatHaveNoCharacter() {
        assertEquals(KeyNotation.from(event: keyEvent("", keyCode: 48, [.option])), "alt-tab")
        assertEquals(KeyNotation.from(event: keyEvent("", keyCode: 126)), "up")
        assertEquals(KeyNotation.from(event: keyEvent("[", keyCode: 33, [.option])), "alt-leftSquareBracket")
    }

    /// A modifier-only press must not be captured -- otherwise merely reaching for ⌥⇧H records
    /// nothing useful and closes the recorder before the real key arrives.
    func testRecorderIgnoresPressesWithNoKey() {
        assertNil(KeyNotation.from(event: keyEvent("", keyCode: 999, [.option])))
    }

    func testPrettyRendersModifiersAsGlyphsAndLeavesBareKeysAlone() {
        assertEquals(KeyNotation.pretty("alt-shift-h"), "⌥⇧h")
        assertEquals(KeyNotation.pretty("h"), "h")
        assertEquals(KeyNotation.pretty("ctrl-alt-cmd-space"), "⌃⌥⌘space")
        // An unknown leading token must survive rather than vanish.
        assertEquals(KeyNotation.pretty("hyper-h"), "hyper-h")
    }

    // MARK: - Menu bar label

    /// The mode chip and a workspace chip can carry the same text (`[R]` mode next to workspace
    /// `R`). `ForEach` needs those to be distinct or one of them disappears from the menu bar.
    func testTrayItemIdSeparatesModesFromWorkspaces() {
        let mode = TrayItem(type: .mode, name: "R", isActive: true)
        let workspace = TrayItem(type: .workspace, name: "R", isActive: true)
        XCTAssertNotEqual(mode.id, workspace.id)
        assertEquals(Set([mode, workspace]).count, 2)
    }

    // MARK: - Branding

    /// The fork's own name, enforced over the settings UI. `BrandingTest` scans the rest of the
    /// tree and lists `Sources/AppBundle/ui` as the one directory still out of scope; this closes
    /// it, and keeps it closed.
    ///
    /// No exceptions. There used to be one -- the settings window had to keep *reading*
    /// `during-aerospace-startup`, because `parseOnWindowDetected` still accepted that matcher key
    /// with a deprecation warning, and reading only the new spelling would have dropped the matcher
    /// on the first GUI edit. The parser no longer accepts it, so a config carrying it does not load
    /// and the read was dead code. Both are gone.
    func testSettingsUiDoesNotMentionTheUpstreamProductName() throws {
        var offenders: [String] = []
        for file in try uiSources() {
            let text = try String(contentsOf: file, encoding: .utf8)
            for (i, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
                where line.lowercased().contains("aerospace")
            {
                offenders.append("\(file.lastPathComponent):\(i + 1): \(line.trimmingCharacters(in: .whitespaces))")
            }
        }
        XCTAssertEqual(offenders, [], "the product is AeroSpork:\n" + offenders.joined(separator: "\n"))
    }

    // MARK: - Deployment floor

    /// `Package.swift` declares macOS 13. APIs newer than that do not fail to build against a newer
    /// SDK -- SwiftUI modifiers are unavailable at *compile* time only if unguarded, and SF Symbols
    /// introduced later simply render as an empty box at runtime. Neither is visible from here, so
    /// the floor is enforced by reading the source.
    func testSettingsUiStaysWithinTheMacOS13Floor() throws {
        // token -> why it is banned
        let banned = [
            "ContentUnavailableView(": "macOS 14; use ContentUnavailableViewCompat",
            ".scrollBounceBehavior": "macOS 14",
            "alternatingRowBackgrounds": "macOS 14",
            ".accessoryBar": "macOS 14 button style",
            ".extraLarge": "macOS 14 control size",
            "MeshGradient": "macOS 15",
            "square.resize": "SF Symbols 5 (macOS 14)",
            "arrow.trianglehead": "SF Symbols 6 (macOS 15)",
        ]
        let files = try uiSources()

        // Anything genuinely newer has to sit behind `#available`, as `MenuBarLabel` does for
        // `ImageRenderer` -- these tokens have no macOS 13 rendering at all, guarded or not.
        for file in files {
            // Comments are stripped first: the whole point of a comment like "square.resize is SF
            // Symbols 5, so we use rectangle.split.3x3" is to record the rule, not break it.
            // TRADEOFF: naive `//` split, so a banned token inside a string containing `//` would
            // be missed. Upgrade path: none needed until a symbol name lives inside a URL.
            let source = try String(contentsOf: file, encoding: .utf8)
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.components(separatedBy: "//").first ?? "" }
                .joined(separator: "\n")
            for (token, reason) in banned where source.contains(token) {
                XCTFail("\(file.lastPathComponent) uses \(token) — \(reason)")
            }
        }
    }
}
