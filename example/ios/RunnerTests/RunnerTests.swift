import Flutter
import UIKit
import XCTest

@testable import ios_window_control_layout

class RunnerTests: XCTestCase {
  func testMissingViewReturnsStableErrorOrUnavailableV2Payload() {
    let plugin = IosWindowControlLayoutPlugin()
    let call = FlutterMethodCall(methodName: "queryLayout", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called")
    plugin.handle(call) { result in
      if #available(iOS 26.0, *) {
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "view_unavailable")
      } else {
        self.assertUnavailablePayload(result as? [String: Any])
      }
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testUnavailablePayloadContainsCompleteV2ZeroValues() {
    assertUnavailablePayload(LayoutPayload.unavailable.encode())
  }

  func testPureQueryPreservesMarginsAndSafeAreas() {
    let payload = IosWindowControlLayoutPlugin.queryLayout(
      baseMargins: insets(1),
      horizontalMargins: insets(5),
      verticalMargins: insets(9),
      baseSafeArea: insets(13),
      horizontalSafeArea: insets(17),
      verticalSafeArea: insets(21)
    )

    XCTAssertTrue(payload.isAvailable)
    XCTAssertEqual(payload.baseMargins.start, 2)
    XCTAssertEqual(payload.horizontalMargins.top, 5)
    XCTAssertEqual(payload.verticalMargins.end, 12)
    XCTAssertEqual(payload.baseSafeArea.bottom, 15)
    XCTAssertEqual(payload.horizontalSafeArea.start, 18)
    XCTAssertEqual(payload.verticalSafeArea.end, 24)
  }

  func testEncodedPayloadHasCorrectFieldsAndDirectionalValues() {
    let layout = IosWindowControlLayoutPlugin.queryLayout(
      baseMargins: insets(1),
      horizontalMargins: insets(5),
      verticalMargins: insets(9),
      baseSafeArea: insets(13),
      horizontalSafeArea: insets(17),
      verticalSafeArea: insets(21)
    ).encode()

    XCTAssertEqual(layout["schemaVersion"] as? Int, 2)
    XCTAssertEqual(layout["isAvailable"] as? Bool, true)
    XCTAssertEqual(Set(layout.keys), Set([
      "schemaVersion", "isAvailable", "baseMargins", "horizontalMargins",
      "verticalMargins", "baseSafeArea", "horizontalSafeArea",
      "verticalSafeArea",
    ]))
    assertInsets(layout["baseMargins"], [2, 1, 4, 3])
    assertInsets(layout["horizontalMargins"], [6, 5, 8, 7])
    assertInsets(layout["verticalMargins"], [10, 9, 12, 11])
    assertInsets(layout["baseSafeArea"], [14, 13, 16, 15])
    assertInsets(layout["horizontalSafeArea"], [18, 17, 20, 19])
    assertInsets(layout["verticalSafeArea"], [22, 21, 24, 23])
  }

  private func insets(_ value: CGFloat) -> NSDirectionalEdgeInsets {
    NSDirectionalEdgeInsets(
      top: value,
      leading: value + 1,
      bottom: value + 2,
      trailing: value + 3
    )
  }

  private func assertInsets(_ value: Any?, _ expected: [Double]) {
    let insets = value as? [String: Double]
    XCTAssertEqual(insets?["start"], expected[0])
    XCTAssertEqual(insets?["top"], expected[1])
    XCTAssertEqual(insets?["end"], expected[2])
    XCTAssertEqual(insets?["bottom"], expected[3])
  }

  private func assertUnavailablePayload(_ layout: [String: Any]?) {
    XCTAssertEqual(layout?["schemaVersion"] as? Int, 2)
    XCTAssertEqual(layout?["isAvailable"] as? Bool, false)
    for field in [
      "baseMargins", "horizontalMargins", "verticalMargins", "baseSafeArea",
      "horizontalSafeArea", "verticalSafeArea",
    ] {
      assertInsets(layout?[field], [0, 0, 0, 0])
    }
  }
}
