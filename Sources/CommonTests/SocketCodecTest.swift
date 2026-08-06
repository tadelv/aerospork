import Common
import Darwin
import Foundation
import XCTest

/// Framing edges that `AppBundleTests/model/UnixSocketTest.swift` does not reach: it covers hostile
/// *headers* (oversized, 0xFFFFFFFF, silent peer). This covers the payload path -- boundaries,
/// empty frames, and payloads larger than the 64 KiB read buffer, where `readExactly`'s partial-read
/// loop is the only thing standing between us and a truncated command.
final class SocketCodecTest: XCTestCase {
  private func pair() -> (a: UnixSocketConnection, b: UnixSocketConnection) {
    var fds: [Int32] = [0, 0]
    XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &fds), 0)
    return (UnixSocketConnection(fd: fds[0]), UnixSocketConnection(fd: fds[1]))
  }

  /// A stream socket does not preserve write boundaries -- the length prefix is the only reason
  /// two back-to-back messages don't arrive as one blob.
  func testConsecutiveMessagesKeepTheirBoundaries() throws {
    let (a, b) = pair()
    defer { a.close()
      b.close() }
    a.sendMessage(Data("first".utf8))
    a.sendMessage(Data("second".utf8))
    XCTAssertEqual(try b.recvMessage(), Data("first".utf8))
    XCTAssertEqual(try b.recvMessage(), Data("second".utf8))
  }

  /// A payload that itself looks like a length header must not resynchronize the stream.
  func testPayloadContainingAHeaderPatternIsNotResplit() throws {
    let (a, b) = pair()
    defer { a.close()
      b.close() }
    let payload = Data([0x00, 0x00, 0x00, 0x05]) + Data("hello".utf8)
    a.sendMessage(payload)
    XCTAssertEqual(try b.recvMessage(), payload)
  }

  /// `writeAll` early-returns on a nil base address and `readExactly(0)` short-circuits, so a
  /// zero-length frame takes a different path in both directions. It must round-trip as empty
  /// data, not as EOF -- `nil` means "the peer hung up" everywhere else.
  func testEmptyPayloadRoundTripsAsEmptyNotEof() throws {
    let (a, b) = pair()
    defer { a.close()
      b.close() }
    a.sendMessage(Data())
    XCTAssertEqual(try b.recvMessage(), Data())
  }

  /// Bigger than the 64 KiB read buffer and than the socket buffer, so both the write loop and
  /// the read loop have to iterate. A config file pushed over the socket is exactly this shape.
  func testPayloadLargerThanTheReadBufferSurvivesPartialReads() throws {
    let (a, b) = pair()
    defer { a.close()
      b.close() }
    let payload = Data((0..<300000).map { UInt8($0 % 251) }) // non-repeating enough to catch a mis-offset
    let sender = Thread { a.sendMessage(payload) } // writes block once the socket buffer fills
    sender.start()
    XCTAssertEqual(try b.recvMessage(), payload)
  }

  /// `sun_path` is a fixed 104-byte buffer. The guard must refuse rather than truncate, because a
  /// truncated path is a *different, possibly existing* socket.
  func testConnectRefusesAPathTooLongForSunPath() {
    XCTAssertNil(UnixSocketConnection.connect(to: "/tmp/" + String(repeating: "x", count: 200) + ".sock"))
    XCTAssertNil(UnixSocketListener.bind(to: "/tmp/" + String(repeating: "x", count: 200) + ".sock"))
  }

  func testRecvReturnsNilAfterThePeerHangsUp() throws {
    let (a, b) = pair()
    defer { b.close() }
    a.close()
    XCTAssertNil(try b.recvMessage())
  }
}
