import AppKit
import Common

/// Alternative name: AttrAddressibleStorage
protocol AxUiElementMock {
    func get<Attr: ReadableAttr>(_ attr: Attr) -> Attr.T?
    /// The AX *write* seam.
    ///
    /// `AXUIElement` already satisfies this from its extension in `accessibility.swift`, so nothing
    /// on the production path changed: every real call site holds a concrete `AXUIElement` (or a
    /// `some AxUiElementMock` generic that specializes to one), which the compiler dispatches
    /// straight to that extension -- the witness table entry is never consulted, and the
    /// `OSSignposter` intervals there are untouched.
    ///
    /// It exists because writes are the half of the AX API that actually fails in production --
    /// silently ignored, clamped to another value, or timed out -- and until now none of that was
    /// reachable from a test.
    @discardableResult func set<Attr: WritableAttr>(_ attr: Attr, _ value: Attr.T) -> Bool
    func containingWindowId() -> CGWindowID?
}

extension AxUiElementMock {
    var cast: AXUIElement? {
        if CFGetTypeID(self as CFTypeRef) == AXUIElementGetTypeID() {
            return (self as! AXUIElement)
        }
        return nil
    }
}
