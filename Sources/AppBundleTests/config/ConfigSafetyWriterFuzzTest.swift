@testable import AppBundle
import Common
import TOMLKit
import XCTest

/// Property test for the line-based config writer.
///
/// `unsupportedShapeReason` is a **denylist** of TOML spellings the writer cannot survive, and a
/// denylist is only as good as the imagination of whoever wrote it. This generates configs from a
/// fixed seed and asserts the one property that matters:
///
/// > for every generated config, EITHER the writer refuses it, OR a no-op render is byte-identical
/// > AND an edited render still parses and preserves every key the edit did not target.
///
/// Fixed seed on purpose. A fuzzer that finds a different bug on every run is a fuzzer nobody can
/// bisect, and a red build nobody can reproduce gets deleted within a month.
@MainActor
final class ConfigSafetyWriterFuzzTest: XCTestCase {
    private static let configsPerEdit = 400

    // MARK: - The property

    func testNoOpRenderIsByteIdentical() {
        forEachGeneratedConfig { text in
            let vm = ConfigurationViewModel()
            vm.markLoaded()
            assertEquals(ConfigurationWriter.render(baseText: text, from: vm), text)
        }
    }

    func testScalarEditPreservesEverythingElse() {
        forEachGeneratedConfig { text in
            let vm = ConfigurationViewModel()
            vm.markLoaded()
            vm.accordionPadding = 4242
            check(text, ConfigurationWriter.render(baseText: text, from: vm), edited: "accordion-padding")
        }
    }

    func testGapsEditPreservesEverythingElse() {
        forEachGeneratedConfig { text in
            let vm = ConfigurationViewModel()
            vm.markLoaded()
            vm.innerGapsHorizontal += 7
            check(text, ConfigurationWriter.render(baseText: text, from: vm), edited: "gaps")
        }
    }

    func testBindingEditPreservesEverythingElse() {
        forEachGeneratedConfig { text in
            let vm = ConfigurationViewModel()
            vm.modes = Self.modeNames(in: text).map { .init(mode: $0, bindings: []) }
            vm.markLoaded()
            vm.addBinding(mode: "main", key: "alt-shift-q", command: "focus left")
            check(text, ConfigurationWriter.render(baseText: text, from: vm), edited: "mode")
        }
    }

    /// The invariant, for one config and one edit.
    private func check(_ before: String, _ after: String, edited: String) {
        switch parseConfig(after) {
            case .failure(let errors):
                XCTFail("edit '\(edited)' produced an unloadable config: \(errors.descriptions)\n--- before ---\n\(before)\n--- after ---\n\(after)")
                return
            case .success: break
        }
        let lost = Self.flatten(before).filter { key, value in
            !key.hasPrefix(edited) && Self.flatten(after)[key] != value
        }
        XCTAssertTrue(
            lost.isEmpty,
            "edit '\(edited)' lost \(lost.keys.sorted())\n--- before ---\n\(before)\n--- after ---\n\(after)",
        )
    }

    /// Runs `body` over every generated config the writer claims it can edit. A refusal is a pass:
    /// pointing the user at the Raw TOML tab is the documented, safe outcome.
    private func forEachGeneratedConfig(_ body: (String) -> Void) {
        var rng = SplitMix64(seed: 0x5EED_C0FF_EE00_1234)
        var edited = 0
        for _ in 0 ..< Self.configsPerEdit {
            let text = Self.generate(&rng)
            // Only configs the app itself would load: an already-broken config proves nothing
            // about the writer.
            guard case .success = parseConfig(text) else { continue }
            guard ConfigurationWriter.unsupportedShapeReason(text) == nil else { continue }
            body(text)
            edited += 1
        }
        // Guards against the generator drifting into producing only refused or only broken configs,
        // which would turn every assertion above into a no-op that passes forever.
        XCTAssertGreaterThan(edited, Self.configsPerEdit / 10, "generator produced almost nothing editable")
    }

    // MARK: - Comparison

    /// `{ "gaps.inner.horizontal": "3" }`. Compared as a dictionary because TOML table order is not
    /// meaningful, and comparing rendered text would fail on formatting the writer is allowed to change.
    private static func flatten(_ text: String) -> [String: String] {
        var out: [String: String] = [:]
        if let table = try? TOMLTable(string: text) { flatten(table, "", into: &out) }
        return out
    }

    private static func flatten(_ value: TOMLValueConvertible, _ path: String, into out: inout [String: String]) {
        if let table = value.table {
            // Not for the root: "the file was empty and now isn't" is the edit, not a loss.
            if table.isEmpty, !path.isEmpty { out[path] = "{}" }
            for (key, sub) in table { flatten(sub, path.isEmpty ? key : "\(path).\(key)", into: &out) }
        } else if let array = value.array {
            if array.isEmpty { out[path] = "[]" }
            for i in 0 ..< array.count { flatten(array[i], "\(path)[\(i)]", into: &out) }
        } else {
            out[path] = value.debugDescription
        }
    }

    private static func modeNames(in text: String) -> [String] {
        let names = (try? TOMLTable(string: text))?["mode"]?.table.map { Array($0.keys) } ?? []
        return names.contains("main") ? names : names + ["main"]
    }

    // MARK: - Generation

    /// Deterministic, self-contained PRNG. `SystemRandomNumberGenerator` would make every failure
    /// unreproducible, which is worse than having no test.
    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    /// Fragments that must appear before any `[section]` header, or the keys after it land inside
    /// that section instead of at the top level.
    private static let preambleFragments: [String] = [
        "start-at-login = false",
        "'start-at-login' = false", // quoted key
        "\"start-at-login\" = false",
        "accordion-padding = 30",
        "accordion-padding=30", // no spaces
        "accordion-padding   =   30", // extra spaces
        "accordion-padding = 30 # keep this note", // trailing comment
        "enable-normalization-flatten-containers = false",
        "after-startup-command = 'exec-and-forget echo hi'",
        "after-startup-command = ['exec-and-forget echo hi', 'exec-and-forget echo there']",
        "after-startup-command = [\n    'exec-and-forget echo hi',\n]", // multi-line array
        "on-focus-changed = [\n  'move-mouse window-lazy-center',\n  'exec-and-forget echo x',\n]",
        "exec-on-workspace-change = []", // deprecated but loadable
        "gaps.inner.horizontal = 5", // dotted spelling of a rewritten section
        "exec = { inherit-env-vars = false }", // inline spelling of a rewritten section
        "# a comment",
        "   # an indented comment",
        "",
        "\t",
    ]

    private static let sectionFragments: [String] = [
        "[gaps]\ninner.horizontal = 3\nouter.top = 8",
        "[gaps]\n    inner.horizontal = 3\n    inner.vertical = 4", // indented
        "[gaps]", // empty section
        "[ gaps ]\ninner.horizontal = 1", // padded header
        "[gaps.inner]\nhorizontal = 6\nvertical = 6",
        "[gaps.outer]\ntop = 1\nbottom = 2\nleft = 3\nright = 4",
        "[gaps]\nouter.top = [{ monitor.\"built-in\" = 3 }, 6]", // per-monitor array the UI can't model
        "[key-mapping]\npreset = 'qwerty'",
        "[key-mapping]\npreset = 'dvorak'\nkey-notation-to-key-code.unicorn = 'u'", // unmodelled key
        "[exec]\ninherit-env-vars = true",
        "[exec]\ninherit-env-vars = false\n\n[exec.env-vars]\nPATH = '/usr/bin'",
        "[exec.env-vars]\n'MY VAR' = 'x'\n\"日本語\" = 'unicode'", // quoted + unicode keys
        "[mode.main.binding]\nalt-h = 'focus left'\nalt-l = 'focus right'",
        "[mode.main.binding]\n    alt-h = 'focus left'\n    alt-r = ['flatten-workspace-tree', 'mode main']",
        "[mode.main]\nbinding.alt-h = 'focus left'", // dotted binding
        "[mode.service.binding]\nesc = ['reload-config', 'mode main']",
        "[mode.main.binding]\nalt-1 = [\n  'workspace 1',\n]", // multi-line binding
        "[workspace-to-monitor-force-assignment]\n1 = 'main'\n2 = ['secondary', 'built-in']",
        "[workspace-to-monitor-force-assignment]\n'my workspace' = { fingerprint = { name = 'ACME Display 32 (1)' } }",
        "[workspace-to-monitor-force-assignment.2.fingerprint]\nuuid = '11111111-2222-3333-4444-555555555555'",
        "[[on-window-detected]]\nif.app-id = 'com.apple.finder'\nrun = ['layout floating']",
        "[[on-window-detected]]\nif.app-name-regex-substring = 'term'\nif.during-aerospork-startup = true\nrun = 'move-node-to-workspace 2'",
        "# documentation for the next section\n[gaps]\ninner.horizontal = 9",
    ]

    private static func generate(_ rng: inout SplitMix64) -> String {
        var parts: [String] = []
        for _ in 0 ..< Int.random(in: 0 ... 5, using: &rng) {
            parts.append(preambleFragments.randomElement(using: &rng)!)
        }
        var sections: [String] = []
        for _ in 0 ..< Int.random(in: 0 ... 4, using: &rng) {
            sections.append(sectionFragments.randomElement(using: &rng)!)
        }
        parts += sections.shuffled(using: &rng)
        let text = parts.joined(separator: Bool.random(using: &rng) ? "\n\n" : "\n")
        return Bool.random(using: &rng) ? text : text.replacingOccurrences(of: "\n", with: "\r\n")
    }
}
