@testable import Common
import XCTest

/// `TomlBacktrace` is the only thing that tells a user *where* in a 200-line config the rejected
/// value is. It is built by string-free composition and rendered once, at the end, so a formatting
/// regression is invisible until someone writes a bad config.
final class TomlErrorFormattingTest: XCTestCase {
    func testRootKeyHasNoLeadingDot() {
        // `.emptyRoot + .key(x)` is special-cased into `.rootKey`, otherwise every message would
        // start with a stray "." -- ".gaps.inner[0]: ...".
        assertEquals((TomlBacktrace.emptyRoot + .key("gaps")).description, "gaps")
    }

    func testNestedPathRendersAsTomlPath() {
        let backtrace = TomlBacktrace.emptyRoot + .key("gaps") + .key("inner") + .key("horizontal") + .index(2)
        assertEquals(backtrace.description, "gaps.inner.horizontal[2]")
    }

    func testEmptyRootMessageHasNoLocationPrefix() {
        // A whole-file complaint must not be prefixed with a location it doesn't have.
        assertEquals(TomlParseError.semantic(.emptyRoot, "unknown key").description, "unknown key")
    }

    func testLocatedMessageIsPrefixedWithItsPath() {
        let backtrace = TomlBacktrace.emptyRoot + .key("mode") + .key("main") + .key("binding")
        assertEquals(TomlParseError.semantic(backtrace, "unknown key").description, "mode.main.binding: unknown key")
    }

    func testSyntaxErrorIsPassedThroughVerbatim() {
        // Syntax errors come from TOMLKit and already carry line/column; adding our own path would
        // point at the wrong place.
        assertEquals(TomlParseError.syntax("expected '=' at line 3").description, "expected '=' at line 3")
    }

    func testIsRootKeyDistinguishesTheFirstSegment() {
        assertTrue((TomlBacktrace.emptyRoot + .key("gaps")).isRootKey)
        assertFalse((TomlBacktrace.emptyRoot + .key("gaps") + .key("inner")).isRootKey)
        assertTrue(TomlBacktrace.emptyRoot.isEmptyRoot)
    }

    func testToParsedTomlAttachesTheBacktrace() {
        let backtrace = TomlBacktrace.emptyRoot + .key("start-at-login")
        let parsed: ParsedToml<Int> = Parsed<Int>.failure("expected bool").toParsedToml(backtrace)
        guard case .failure(let error) = parsed else { return XCTFail("expected a failure") }
        assertEquals(error.description, "start-at-login: expected bool")
        assertEquals(error, .semantic(backtrace, "expected bool"))
    }

    /// The CLI renders multi-line errors with a hanging indent; losing it makes a two-error report
    /// unreadable in a terminal.
    func testJoinErrorsIndentsContinuationLines() {
        assertEquals(["one\nmore about one", "two"].joinErrors(), "ERROR: one\n       more about one\nERROR: two")
    }
}

private func assertFalse(_ actual: Bool, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertFalse(actual, file: file, line: line)
}
