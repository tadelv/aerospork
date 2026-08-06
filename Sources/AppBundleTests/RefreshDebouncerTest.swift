@testable import AppBundle
import Common
import XCTest

/// Issue #1 regression: the old debouncer cancelled any in-flight refresh when a debounced event
/// fired, so a sustained stream of events (slower than the 50ms debounce, faster than a refresh)
/// starved refreshes to zero completions. The coordinator must let the running refresh finish and
/// run exactly one follow-up with the latest event.
@MainActor
final class RefreshDebouncerTest: XCTestCase {
  private struct Run {
    var event: String
    var start: Date
    var end: Date?
  }

  private final class Recorder {
    var runs: [Run] = []
    var lastStarted = Date.distantPast
    var runCount = 0
    var didRun = false
    var finishedCancelled: Bool?
    var events: [String] = []
    var start: Date?
  }

  private func waitUntilQuiescent(_ recorder: Recorder, lastEvent: String, timeout: TimeInterval = 8) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      try? await Task.sleep(for: .milliseconds(50))
      let lastRun = recorder.runs.last
      if lastRun?.event == lastEvent,
         lastRun?.end != nil,
         Date().timeIntervalSince(recorder.lastStarted) > 0.3
      {
        return
      }
    }
    XCTFail("Refreshes never became quiescent; runs: \(recorder.runs)")
  }

  /// A worker that takes ~400ms while events arrive every 100ms: the old debouncer cancelled
  /// every in-flight refresh, so none completed. At least one must complete, the final event must
  /// be picked up by a completed refresh, and workers must never overlap.
  func testSustainedEventsDoNotStarveRefreshCompletion() async throws {
    let recorder = Recorder()
    let debouncer = RefreshDebouncer(delay: 0.05) { event, _ in
      let start = Date()
      recorder.lastStarted = start
      try? await Task.sleep(for: .milliseconds(400))
      recorder.runs.append(Run(event: event.description, start: start, end: Date()))
    }

    // 15 events, one every 100ms: slower than the debounce, faster than the worker.
    let driving = Task { @MainActor in
      for i in 0..<15 {
        debouncer.debounce(event: .ax("e\(i)"), screenIsDefinitelyUnlocked: false)
        try? await Task.sleep(for: .milliseconds(100))
      }
    }
    await driving.value
    await waitUntilQuiescent(recorder, lastEvent: "ax(e14)")

    assertTrue(!recorder.runs.isEmpty)
    assertTrue(recorder.runs.contains { $0.end != nil })
    if !recorder.runs.contains(where: { $0.event == "ax(e14)" && $0.end != nil }) {
      XCTFail("the final event must be reflected by a completed refresh; runs: \(recorder.runs)")
    }

    let ordered = recorder.runs.sorted { $0.start < $1.start }
    for i in 1..<ordered.count {
      if ordered[i].start < (ordered[i - 1].end ?? .distantFuture) {
        XCTFail("refresh workers must not overlap: \(ordered)")
      }
    }
  }

  /// Five debounced events in one synchronous burst cancel each other's pending timer: exactly
  /// one refresh runs, with the latest event.
  func testBurstFasterThanDebounceCoalescesIntoSingleRefresh() async {
    let recorder = Recorder()
    let debouncer = RefreshDebouncer(delay: 0.05) { event, _ in recorder.events.append(event.description) }
    for i in 0..<5 {
      debouncer.debounce(event: .ax("burst\(i)"), screenIsDefinitelyUnlocked: false)
    }
    try? await Task.sleep(for: .milliseconds(300)) // debounce delay + worker + margin
    assertEquals(recorder.events.count, 1)
    assertTrue(recorder.events.first == "ax(burst4)") // the latest event wins
  }

  /// `runSession` priority: the in-flight refresh is cancelled, and no follow-up runs -- the
  /// session's own body lays out instead.
  func testRunSessionCancelsInFlightRefreshAndSuppressesFollowUp() async throws {
    let recorder = Recorder()
    let debouncer = RefreshDebouncer(delay: 0.05) { _, _ in
      recorder.didRun = true
      recorder.runCount += 1
      defer { recorder.finishedCancelled = Task.isCancelled }
      try? await Task.sleep(for: .milliseconds(200))
    }
    debouncer.debounce(event: .ax("a"), screenIsDefinitelyUnlocked: false)
    try? await Task.sleep(for: .milliseconds(100)) // debounce fired, worker running
    debouncer.cancelRunning() // runSession takes over
    try? await Task.sleep(for: .milliseconds(400)) // old worker unwinds, no follow-up runs

    assertTrue(recorder.didRun)
    assertEquals(recorder.runCount, 1) // no follow-up: the session owns the state now
    if recorder.finishedCancelled != true {
      XCTFail("the in-flight refresh must be cancelled")
    }
  }

  /// The non-debounced path starts immediately, without waiting out the debounce delay.
  func testRefreshImmediatelyStartsWithoutDebounceDelay() async throws {
    let recorder = Recorder()
    let debouncer = RefreshDebouncer(delay: 0.05) { _, _ in recorder.start = Date() }
    debouncer.refreshImmediately(event: .ax("now"), screenIsDefinitelyUnlocked: false)
    try? await Task.sleep(for: .milliseconds(20)) // well under the 50ms debounce delay
    assertNotNil(recorder.start)
  }

  /// A non-debounced refresh preempts an in-flight debounced one: the slow worker is cancelled
  /// and the fresh one still completes.
  func testRefreshImmediatelyPreemptsRunningRefreshAndStillCompletes() async throws {
    let recorder = Recorder()
    let debouncer = RefreshDebouncer(delay: 0.05) { event, _ in
      try? await Task.sleep(for: .milliseconds(100))
      if !Task.isCancelled {
        recorder.events.append(event.description)
      }
    }
    debouncer.debounce(event: .ax("slow"), screenIsDefinitelyUnlocked: false)
    try? await Task.sleep(for: .milliseconds(100)) // slow worker running
    debouncer.refreshImmediately(event: .ax("fast"), screenIsDefinitelyUnlocked: false)
    try? await Task.sleep(for: .milliseconds(300))

    assertEquals(recorder.events, ["ax(fast)"]) // the slow worker was cancelled, fast one completed
  }
}
