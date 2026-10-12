@testable import AppBundle
import AppKit
import Common
import XCTest

/// Covers `tabGroups`: macOS reports a window with native tabs as one AX window per tab, and
/// managing all of them lays one window out against itself.
final class TabGroupsTest: XCTestCase {
  func testAxWindowsAtTheSameRectAreOneWindow() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window(), 3: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, sameRect), (3, sameRect)]))
    // The tab furthest from the front: Cmd+W closes the visible one, not this one.
    assertEquals(groups.managed, [3])
    assertEquals(groups.selected, [3: 1]) // reads and writes go to the tab the user sees
    assertEquals(groups.owner, [1: 3, 2: 3, 3: 3])
  }

  func testGroupingIgnoresWindowsOfOtherRectanglesInBetween() {
    // WindowServer's list is global, so a group's members are not adjacent in it.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 9: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (9, elsewhere), (2, sameRect)]))
    assertEquals(Set(groups.managed), Set([2, 9]))
    assertEquals(groups.owner, [1: 2, 2: 2])
    assertEquals(groups.selected, [2: 1, 9: 9])
  }

  func testTabSwitchAndNewTabKeepTheManagedId() {
    let windows: [UInt32: any AxUiElementMock] = [4: window(), 5: window()]
    // 4 is the managed id, 5 a tab the user opened or switched to: the node must survive both.
    var groups = tabGroups(of: windows, in: inputs([(5, sameRect), (4, sameRect)], alreadyManaged: [4]))
    assertEquals(groups.managed, [4])
    assertEquals(groups.selected, [4: 5])
    groups = tabGroups(of: windows, in: inputs([(4, sameRect), (5, sameRect)], alreadyManaged: [4]))
    assertEquals(groups.managed, [4])
    assertEquals(groups.selected, [4: 4])
  }

  /// Frames are read before layout writes them, so a group's members disagree for exactly one
  /// refresh when its workspace moves to another monitor, or when the screen wakes. Geometry alone
  /// split them there and nothing reunited them afterwards: a window that became its own node is no
  /// longer a tab, so the next refresh could not tell it ever was one.
  func testTabsStayOneWindowWhileTheirFramesDisagree() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window(), 3: window()]
    let groups = tabGroups(of: windows, in: inputs(
      [(1, sameRect), (2, elsewhere), (3, anotherRect)],
      alreadyManaged: [1],
      undrawn: [2, 3],
      previousOwner: [1: 1, 2: 1, 3: 1]
    ))
    assertEquals(groups.managed, [1])
    assertEquals(groups.selected, [1: 1])
    assertEquals(groups.owner, [1: 1, 2: 1, 3: 1])
  }

  /// Native tab windows reach the AX layer intermittently: Ghostty reports its visible tab alone for
  /// long stretches and every tab while it is reconfiguring, so the refresh that finally sees them
  /// again is not the one after the last one that did. Geometry then compares rectangles that a wake
  /// or a monitor change left disagreeing, and a refresh that had forgotten the group takes it apart.
  func testTabsAreReunitedAfterARefreshThatDidNotSeeThem() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window(), 3: window()]
    let groups = tabGroups(of: windows, in: inputs(
      [(1, sameRect), (2, elsewhere), (3, anotherRect)],
      alreadyManaged: [1],
      undrawn: [2, 3],
      rememberedOwner: [1: 1, 2: 1, 3: 1]
    ))
    assertEquals(groups.managed, [1])
    assertEquals(groups.owner, [1: 1, 2: 1, 3: 1])
  }

  /// The memory is still only a memory: a second drawn window is never pulled back into a group, so a
  /// tab dragged out into a window of its own keeps its rectangle.
  func testRememberedTabsDoNotReabsorbAWindowThatBecameItsOwn() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs(
      [(1, sameRect), (2, elsewhere)],
      alreadyManaged: [1, 2],
      rememberedOwner: [1: 1, 2: 1]
    ))
    assertEquals(Set(groups.managed), Set([1, 2]))
  }

  /// What the next refresh keeps: an id that has become a window of its own is dropped, and one the
  /// app reported not at all is kept -- that gap is what this memory exists for.
  func testOnlyTheIdsTheAppStoppedReportingAreRemembered() {
    let remembered = rememberedOwnersAfterRefresh([1: 1], [1: 1, 2: 1, 3: 1], aliveWindowIds: [1, 2])
    assertEquals(remembered, [1: 1, 3: 1])
  }

  /// ...but a tab the user dragged out into a window of its own is drawn at a rectangle of its own,
  /// and it is meant to keep it. Undrawn siblings are what gets reunited, not a second visible window.
  func testATabDraggedOutIntoItsOwnWindowIsNotReunited() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs(
      [(1, sameRect), (2, elsewhere)],
      alreadyManaged: [1, 2],
      previousOwner: [1: 1, 2: 1]
    ))
    assertEquals(Set(groups.managed), Set([1, 2]))
    assertEquals(groups.owner, [:])
  }

  /// Two windows that were never one group cannot be merged into one, whatever the previous
  /// refresh's map holds for a window of some other app's group.
  func testTwoSeparateWindowsAreNeverReunited() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs(
      [(1, sameRect), (2, elsewhere)],
      alreadyManaged: [1, 2],
      previousOwner: [1: 1, 2: 2]
    ))
    assertEquals(Set(groups.managed), Set([1, 2]))
  }

  func testWindowsAtDistinctRectsAreSeparateWindows() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, elsewhere)]))
    assertEquals(Set(groups.managed), Set([1, 2]))
    assertEquals(groups.selected, [1: 1, 2: 2])
    assertEquals(groups.owner, [:])
  }

  func testWindowsAeroSporkParkedInTheSameCornerAreNotTabs() {
    // hideInCorner parks same-sized hidden windows of one app on the same rect on purpose. Merging
    // those would drop a window out of the layout.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, sameRect)], parkedInCorner: [1, 2]))
    assertEquals(Set(groups.managed), Set([1, 2]))
  }

  func testOneParkedWindowDoesNotStopAGroupFromBeingCollapsed() {
    // A tab group on a hidden workspace is parked as one window, so only its managed id is parked.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, sameRect)], alreadyManaged: [1], parkedInCorner: [1]))
    assertEquals(groups.managed, [1])
  }

  func testAPanelPlacedOverItsOwnWindowIsNotATab() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window(kAXDialogSubrole)]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, sameRect)]))
    assertEquals(Set(groups.managed), Set([1, 2]))
  }

  func testAWindowWithNoWindowServerRectIsASeparateWindowUntilTheNextRefresh() {
    // A tab created between the WindowServer query and the AX read is its own window for one
    // refresh; the next refresh collapses it back into the group.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    var groups = tabGroups(of: windows, in: inputs([(1, sameRect)]))
    assertEquals(Set(groups.managed), Set([1, 2]))
    groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, sameRect)], alreadyManaged: [1, 2]))
    assertEquals(groups.managed, [1])
    assertEquals(groups.selected, [1: 1])
  }

  func testAFloatingDuplicateWithASlightlyDifferentSizeIsTheSameWindow() {
    // A duplicate node left behind by this bug keeps whatever frame it was last given, so its size
    // can differ from its twin's by the slack the layout leaves behind.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, aBitShorter)], floatingWindowIds: [1, 2]))
    assertEquals(groups.managed, [2])
    assertEquals(groups.selected, [2: 1])
  }

  func testNearlyIdenticalTiledRectsStaySeparateWindows() {
    // Only floating windows may match loosely. A container lays its children out itself, and an
    // accordion deliberately overlaps them, so two nearly identical tiled rectangles are two windows.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, aBitShorter)]))
    assertEquals(Set(groups.managed), Set([1, 2]))
  }

  func testClosingTheTabThatHeldTheGroupIdKeepsThatId() {
    // The group's id is not a member any more (the tab it came from was closed), but the survivors
    // still point at it. A tree node cannot change its windowId, so adopting a new id here would
    // destroy and re-create the node -- the window jumping to another tile, which is what the user
    // saw when closing tabs.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs(
      [(1, sameRect), (2, sameRect)],
      previousOwner: [1: 9, 2: 9]
    ))
    assertEquals(groups.managed, [9])
    assertEquals(groups.owner, [1: 9, 2: 9])
  }

  func testAnUndrawnWindowNearlyOverADrawnOneIsItsTab() {
    // A native tab group composites only the selected tab, so the others sit at (nearly) the same
    // place without being drawn. Nothing AX reports says so; this is observable only to WindowServer.
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window(), 3: window()]
    let groups = tabGroups(of: windows, in: inputs(
      [(1, sameRect), (2, aBitShorter), (3, sameRect)],
      undrawn: [2, 3]
    ))
    assertEquals(groups.managed, [3])
    assertEquals(groups.selected, [3: 1]) // he sees tab 1
  }

  func testFloatingWindowsThatMerelyOverlapStaySeparate() {
    let windows: [UInt32: any AxUiElementMock] = [1: window(), 2: window()]
    let groups = tabGroups(of: windows, in: inputs([(1, sameRect), (2, halfOverlapping)], floatingWindowIds: [1, 2]))
    assertEquals(Set(groups.managed), Set([1, 2]))
  }

  private let sameRect = WindowServerRect(CGRect(x: 100, y: 200, width: 800, height: 600))
  private let elsewhere = WindowServerRect(CGRect(x: 900, y: 200, width: 800, height: 600))
  /// Same origin, 30 points shorter: the slack one tab member can hold over another.
  private let aBitShorter = WindowServerRect(CGRect(x: 100, y: 200, width: 800, height: 570))
  private let halfOverlapping = WindowServerRect(CGRect(x: 500, y: 200, width: 800, height: 600))
  /// A third place entirely: where a tab sits while its sibling has already been laid out elsewhere.
  private let anotherRect = WindowServerRect(CGRect(x: 100, y: 900, width: 800, height: 600))

  private func window(_ subrole: String = kAXStandardWindowSubrole) -> [String: Json] {
    ["AXSubrole": .string(subrole)]
  }

  private func inputs(
    _ windowServerRects: [(UInt32, WindowServerRect)],
    alreadyManaged: Set<UInt32> = [],
    parkedInCorner: Set<UInt32> = [],
    floatingWindowIds: Set<UInt32> = [],
    undrawn: Set<UInt32> = [],
    previousOwner: [UInt32: UInt32] = [:],
    rememberedOwner: [UInt32: UInt32] = [:]
  ) -> TabGroupInputs {
    TabGroupInputs(
      windowServerRects: windowServerRects.map { (windowId: $0.0, rect: $0.1, isDrawn: !undrawn.contains($0.0)) },
      alreadyManaged: alreadyManaged,
      parkedInCorner: parkedInCorner,
      floatingWindowIds: floatingWindowIds,
      previousOwner: previousOwner,
      rememberedOwner: rememberedOwner
    )
  }
}
