@testable import AppBundle
import Common
import XCTest

/// Regression tests for the settings writer.
///
/// Every case here was a CONFIRMED defect: the writer either produced clean-parsing TOML with the
/// user's data quietly removed, or produced a duplicate-key parse error that blocked all future
/// saves. They are grouped by the guarantee they defend.
@MainActor
final class ConfigurationWriterSafetyTest: XCTestCase {
    private func errors(_ toml: String) -> [String] {
        switch parseConfig(toml) {
            case .success: return []
            case .failure(let e): return e.map(\.description)
        }
    }

    /// A view model that believes `base` is what it loaded.
    private func loadedVM() -> ConfigurationViewModel {
        let vm = ConfigurationViewModel()
        vm.markLoaded()
        return vm
    }

    // MARK: - Shapes the line-based writer must REFUSE rather than corrupt

    func testRefusesMultiLineArray() {
        let base = """
            after-startup-command = [
                'exec-and-forget echo one',
            ]
            """
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason(base))
    }

    func testRefusesQuotedTopLevelKey() {
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason("'start-at-login' = false"))
    }

    func testRefusesDottedAndInlineManagedSections() {
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason("gaps.inner.horizontal = 5"))
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason("exec = { inherit-env-vars = false }"))
    }

    func testRefusesDottedBindings() {
        let base = """
            [mode.main]
            binding.alt-h = 'focus left'
            """
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason(base))
    }

    func testRefusesFingerprintSubTable() {
        let base = """
            [workspace-to-monitor-force-assignment.2.fingerprint]
            uuid = '11111111-2222-3333-4444-555555555555'
            """
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason(base))
    }

    /// A key inside a rewritten section that the writer does not re-emit would simply vanish.
    func testRefusesUnmodelledKeyInsideRewrittenSection() {
        let base = """
            [key-mapping]
            preset = 'qwerty'
            key-notation-to-key-code.unicorn = 'u'
            """
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason(base))
    }

    /// The shipped default must stay inside the supported subset, or new users hit refusals.
    func testShippedDefaultConfigIsEditable() throws {
        let text = try String(contentsOf: defaultConfigUrl, encoding: .utf8)
        assertEquals(errors(text), [])
        XCTAssertNil(ConfigurationWriter.unsupportedShapeReason(text), "shipped default is not GUI-editable")
    }

    /// Ordinary configs must NOT be refused -- the guard has to be narrow to be useful.
    func testOrdinaryConfigIsNotRefused() {
        let base = """
            start-at-login = false

            [gaps]
            inner.horizontal = 3

            [gaps.outer]
            top = 8

            [mode.main.binding]
            alt-h = 'focus left'

            [[on-window-detected]]
            if.app-id = 'com.apple.finder'
            run = ['layout floating']
            """
        XCTAssertNil(ConfigurationWriter.unsupportedShapeReason(base), "false positive on a normal config")
    }

    // MARK: - Silent data loss

    /// Re-binding a key used to write nothing while the UI reported success.
    func testRebindingExistingKeyIsWritten() {
        let base = """
            [mode.main.binding]
            alt-h = 'focus left'
            """
        let vm = ConfigurationViewModel()
        vm.modes = [.init(mode: "main", bindings: [.init(key: "alt-h", command: "focus left")])]
        vm.markLoaded()
        vm.addBinding(mode: "main", key: "alt-h", command: "focus right")

        let out = ConfigurationWriter.render(baseText: base, from: vm)
        XCTAssertTrue(out.contains("focus right"), "rebind was silently dropped:\n\(out)")
        XCTAssertFalse(out.contains("focus left"), "old command survived:\n\(out)")
        assertEquals(errors(out), [])
    }

    /// Removing one section must not swallow the comments documenting the NEXT one.
    func testCommentsBeforeAnUntouchedSectionSurvive() {
        let base = """
            [exec]
            inherit-env-vars = true

            # my carefully documented gaps
            [gaps]
            inner.horizontal = 3
            """
        let vm = ConfigurationViewModel()
        vm.execInheritEnvVars = true
        vm.markLoaded()
        vm.execInheritEnvVars = false

        let out = ConfigurationWriter.render(baseText: base, from: vm)
        XCTAssertTrue(out.contains("# my carefully documented gaps"), "comment was eaten:\n\(out)")
    }

    /// `if.during-aerospork-startup` had no field in the row model, so any edit deleted it --
    /// turning a startup-only rule into one that fires for every matching window forever.
    func testWindowRuleDuringStartupSurvivesAnEdit() {
        let base = """
            [[on-window-detected]]
            if.app-id = 'com.apple.finder'
            if.during-aerospork-startup = true
            run = ['layout floating']
            """
        let vm = ConfigurationViewModel()
        vm.windowRules = [.init(
            appId: "com.apple.finder",
            run: "layout floating",
            duringStartup: true,
        )]
        vm.markLoaded()
        vm.windowRules[0].workspace = "5"

        let out = ConfigurationWriter.render(baseText: base, from: vm)
        // What must never happen is the matcher disappearing.
        XCTAssertTrue(out.contains("during-aerospork-startup"), "startup matcher dropped:\n\(out)")
        assertEquals(errors(out), [])

        // ...and it round-trips: reading `out` back must still see a startup-only rule.
        let reloaded = ConfigurationViewModel()
        reloaded.loadWindowRules(fromText: out)
        assertEquals(reloaded.windowRules.first?.duringStartup, true)
    }

    // MARK: - Output must be valid TOML

    func testKeysNeedingQuotesAreQuoted() {
        let vm = loadedVM()
        vm.execEnvVars = [.init(name: "MY VAR", value: "x")]
        vm.assignments = [.init(workspace: "my workspace", monitor: "main")]

        let out = ConfigurationWriter.render(baseText: "", from: vm)
        assertEquals(errors(out), [])
    }

    /// A bare monitor string is parsed as a REGEX, so a literal display name containing regex
    /// metacharacters never matched. macOS names duplicate panels exactly that way.
    func testMonitorNameIsNotEmittedAsABareRegex() {
        let vm = loadedVM()
        vm.assignments = [.init(workspace: "1", monitor: "ACME Display 32 (1)")]

        let out = ConfigurationWriter.render(baseText: "", from: vm)
        assertEquals(errors(out), [])
        XCTAssertFalse(
            out.contains("1 = 'ACME Display 32 (1)'"),
            "emitted as a regex that cannot match its own display:\n\(out)",
        )
    }

    // MARK: - Line endings

    /// A CRLF config used to be corrupted on every structured edit. `sectionHeaderName` requires a
    /// line to END with "]", and splitting on "\n" alone leaves "[gaps]\r" -- so neither the writer
    /// nor the shape guard recognised the section, and the writer appended a SECOND [gaps] table.
    /// The property fuzzer attributed the majority of its findings to this one cause.
    func testCrlfConfigIsNotCorrupted() {
        let base = "accordion-padding = 30\r\n\r\n[gaps]\r\ninner.horizontal = 3\r\n"
        let vm = ConfigurationViewModel()
        vm.accordionPadding = 30
        vm.innerGapsHorizontal = 3
        vm.markLoaded()
        vm.innerGapsHorizontal = 9

        XCTAssertNil(ConfigurationWriter.unsupportedShapeReason(base))
        let out = ConfigurationWriter.render(baseText: base, from: vm)
        assertEquals(errors(out), [])
        XCTAssertEqual(out.components(separatedBy: "[gaps]").count - 1, 1, "duplicated the section:\n\(out)")
        XCTAssertTrue(out.contains("\r\n"), "silently rewrote the file's line endings:\n\(out.debugDescription)")
    }

    // MARK: - Raw TOML must not act without Apply

    /// An unapplied raw buffer used to hijack an unrelated structured edit: the toggle was
    /// discarded and the half-finished raw text was committed without Apply ever being pressed.
    func testUnappliedRawTomlDoesNotHijackStructuredEdit() {
        let base = "accordion-padding = 30\nstart-at-login = false\n"
        let vm = ConfigurationViewModel()
        vm.rawToml = base
        vm.accordionPadding = 30
        vm.startAtLogin = false
        vm.markLoaded()

        vm.rawToml = "accordion-padding = 30\n" // edited, NOT applied
        vm.startAtLogin = true // unrelated structured edit

        let out = ConfigurationWriter.render(baseText: base, from: vm)
        XCTAssertTrue(out.contains("start-at-login = true"), "structured edit was discarded:\n\(out)")
    }

    func testRawTomlWinsOnlyWhenApplyRequested() {
        let vm = loadedVM()
        vm.rawToml = "accordion-padding = 7\n"
        vm.accordionPadding = 999
        vm.rawTomlApplyRequested = true

        assertEquals(ConfigurationWriter.render(baseText: "accordion-padding = 30", from: vm), "accordion-padding = 7\n")
    }
}

/// The damage this guard exists to prevent, taken verbatim from a real config it destroyed.
@MainActor
final class MonitorFingerprintNotDegradedTest: XCTestCase {
    /// Two physically identical panels. `display_name` alone cannot tell them apart on reconnect --
    /// the `(1)`/`(2)` suffixes are assigned by connection order -- so the config pins them by
    /// resolution as well. The view model can only hold one token per assignment, and
    /// `formatMonitorValue` can only emit a name, so a rewrite replaced both lines with bare names
    /// and threw the disambiguation away.
    private static let realConfig = """
        [monitors]
        2 = { fingerprint = { display_name = 'ACME Display 32 (1)', height = 2160, width = 3840 } }
        3 = { fingerprint = { display_name = 'ACME Display 32 (2)', height = 2160, width = 3840 } }
        """

    func testARicherFingerprintIsRefusedNotDegraded() {
        let reason = ConfigurationWriter.unsupportedShapeReason(Self.realConfig)
        XCTAssertNotNil(reason, "a fingerprint the editor cannot represent must be refused:\n\(Self.realConfig)")
        XCTAssertTrue(reason?.contains("Raw TOML") == true, reason ?? "")
    }

    /// The v1 spelling of the same section is equally affected.
    func testTheV1SectionNameIsCoveredToo() {
        let v1 = """
            [workspace-to-monitor-force-assignment]
            2 = { fingerprint = { display_name = 'ACME Display 32 (1)', width = 3840, height = 2160 } }
            """
        XCTAssertNotNil(ConfigurationWriter.unsupportedShapeReason(v1))
    }

    /// The guard has to stay narrow: a fingerprint the editor CAN represent must remain editable,
    /// or every user with a monitor assignment loses the Monitors tab.
    func testAPlainNameOrUuidFingerprintIsStillEditable() {
        let editable = """
            [monitors]
            1 = { fingerprint = { name = 'ACME Display 49' } }
            2 = { fingerprint = { uuid = 'AAAAAAAA-0000-4000-8000-000000000001' } }
            3 = 'main'
            """
        XCTAssertNil(ConfigurationWriter.unsupportedShapeReason(editable), "false positive on a representable config")
    }
}
