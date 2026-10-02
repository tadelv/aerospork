@testable import AppBundle
import AppKit
import XCTest

@MainActor
final class KeyRecorderViewTest: XCTestCase {
  /// Pins the native text path replacing the crashing NSString measurement. This is not proof
  /// that the intermittent CoreText exception is gone in a long-running app.
  func testNativeLabelTracksNotationAndRecordingAcrossHiddenRedraws() throws {
    let view = KeyRecorderField.RecorderView(frame: NSRect(x: 0, y: 0, width: 170, height: 22))
    let label = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    XCTAssertFalse(label.isEditable)
    XCTAssertFalse(label.isSelectable)
    XCTAssertEqual(label.cell?.lineBreakMode, .byTruncatingTail)
    XCTAssertEqual(label.stringValue, "Click to record")
    _ = view.becomeFirstResponder()
    XCTAssertEqual(label.stringValue, "Press a shortcut…")
    _ = view.resignFirstResponder()

    // An offscreen window gives native controls a host without opening anything on the desktop.
    let window = NSWindow(contentRect: view.bounds, styleMask: .borderless, backing: .buffered, defer: false)
    window.contentView = view
    for name in [NSAppearance.Name.aqua, .darkAqua] {
      view.appearance = NSAppearance(named: name)
      for notation in ["", "alt-h", "ctrl-alt-shift-9", "alt-shift-leftSquareBracket"] {
        view.displayed = notation
        XCTAssertEqual(label.stringValue, notation.isEmpty ? "Click to record" : KeyNotation.pretty(notation))
        XCTAssertEqual(view.accessibilityValue() as? String, KeyNotation.pretty(notation))
        view.layoutSubtreeIfNeeded()
        // AppKit labels have drawing insets; Auto Layout constrains their alignment rect.
        let textRect = label.alignmentRect(forFrame: label.frame)
        XCTAssertEqual(textRect.minX, 8, accuracy: 0.5)
        XCTAssertEqual(textRect.maxX, view.bounds.width - 8, accuracy: 0.5)
        XCTAssertEqual(textRect.midY, view.bounds.midY, accuracy: 0.5)
        XCTAssertTrue(view.hitTest(NSPoint(x: 20, y: 11)) === view, "The label must not swallow recorder clicks")
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
      }
    }
    XCTAssertFalse(window.isVisible)
  }

  func testNativeLabelDoesNotInterceptCommandShortcutCapture() throws {
    let view = KeyRecorderField.RecorderView(frame: NSRect(x: 0, y: 0, width: 170, height: 22))
    let window = NSWindow(contentRect: view.bounds, styleMask: .borderless, backing: .buffered, defer: false)
    window.contentView = view
    var captured: String?
    view.onCapture = { captured = $0 }
    XCTAssertTrue(window.makeFirstResponder(view))
    let event = try XCTUnwrap(NSEvent.keyEvent(
      with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
      windowNumber: window.windowNumber, context: nil, characters: "q",
      charactersIgnoringModifiers: "q", isARepeat: false, keyCode: 12
    ))
    XCTAssertTrue(view.performKeyEquivalent(with: event))
    XCTAssertEqual(captured, "cmd-q")
    XCTAssertEqual(view.displayed, "cmd-q")
    XCTAssertFalse(window.firstResponder === view)
  }
}
