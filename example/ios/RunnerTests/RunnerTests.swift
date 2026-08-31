import Flutter
import UIKit
import XCTest

@testable import ios_window_control_layout

class RunnerTests: XCTestCase {
  func testMissingViewReturnsStableErrorOrUnavailableV4Payload() {
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

  func testUnavailablePayloadContainsCompleteV4ZeroValues() {
    assertUnavailablePayload(LayoutPayload.unavailable.encode())
  }

  func testFullscreenRequiresExactSceneAndScreenCoverage() {
    XCTAssertTrue(
      IosWindowControlLayoutPlugin.isFullScreen(
        sceneBoundsInScreen: CGRect(x: 0, y: 0, width: 1024, height: 1366),
        screenBounds: CGRect(x: 0, y: 0, width: 1024, height: 1366)
      )
    )
    XCTAssertFalse(
      IosWindowControlLayoutPlugin.isFullScreen(
        sceneBoundsInScreen: CGRect(x: 80, y: 120, width: 900, height: 1100),
        screenBounds: CGRect(x: 0, y: 0, width: 1024, height: 1366)
      )
    )
    XCTAssertFalse(
      IosWindowControlLayoutPlugin.isFullScreen(
        sceneBoundsInScreen: CGRect(x: 0, y: 0, width: 1024, height: 1365.5),
        screenBounds: CGRect(x: 0, y: 0, width: 1024, height: 1366)
      )
    )
  }

  func testPureQueryPreservesMarginsAndSafeAreas() {
    let payload = IosWindowControlLayoutPlugin.queryLayout(
      isPad: true,
      isFullScreen: false,
      baseMargins: insets(1),
      horizontalMargins: insets(5),
      verticalMargins: insets(9),
      baseSafeArea: insets(13),
      horizontalSafeArea: insets(17),
      verticalSafeArea: insets(21),
      effectiveCornerRadii: radii(25)
    )

    XCTAssertTrue(payload.isAvailable)
    XCTAssertTrue(payload.isPad)
    XCTAssertFalse(payload.isFullScreen)
    XCTAssertEqual(payload.baseMargins.start, 2)
    XCTAssertEqual(payload.horizontalMargins.top, 5)
    XCTAssertEqual(payload.verticalMargins.end, 12)
    XCTAssertEqual(payload.baseSafeArea.bottom, 15)
    XCTAssertEqual(payload.horizontalSafeArea.start, 18)
    XCTAssertEqual(payload.verticalSafeArea.end, 24)
    XCTAssertEqual(payload.effectiveCornerRadii.bottomRight, 28)
  }

  func testEncodedPayloadHasCorrectFieldsAndDirectionalValues() {
    let layout = IosWindowControlLayoutPlugin.queryLayout(
      isPad: true,
      isFullScreen: false,
      baseMargins: insets(1),
      horizontalMargins: insets(5),
      verticalMargins: insets(9),
      baseSafeArea: insets(13),
      horizontalSafeArea: insets(17),
      verticalSafeArea: insets(21),
      effectiveCornerRadii: radii(25)
    ).encode()

    XCTAssertEqual(layout["schemaVersion"] as? Int, 4)
    XCTAssertEqual(layout["isAvailable"] as? Bool, true)
    XCTAssertEqual(layout["isPad"] as? Bool, true)
    XCTAssertEqual(layout["isFullScreen"] as? Bool, false)
    XCTAssertEqual(Set(layout.keys), Set([
      "schemaVersion", "isAvailable", "isPad", "isFullScreen",
      "baseMargins", "horizontalMargins", "verticalMargins", "baseSafeArea",
      "horizontalSafeArea", "verticalSafeArea", "effectiveCornerRadii",
    ]))
    assertInsets(layout["baseMargins"], [2, 1, 4, 3])
    assertInsets(layout["horizontalMargins"], [6, 5, 8, 7])
    assertInsets(layout["verticalMargins"], [10, 9, 12, 11])
    assertInsets(layout["baseSafeArea"], [14, 13, 16, 15])
    assertInsets(layout["horizontalSafeArea"], [18, 17, 20, 19])
    assertInsets(layout["verticalSafeArea"], [22, 21, 24, 23])
    assertRadii(layout["effectiveCornerRadii"], [25, 26, 27, 28])
  }

  private func insets(_ value: CGFloat) -> NSDirectionalEdgeInsets {
    NSDirectionalEdgeInsets(
      top: value,
      leading: value + 1,
      bottom: value + 2,
      trailing: value + 3
    )
  }

  private func radii(_ value: Double) -> CornerRadiiPayload {
    CornerRadiiPayload(
      topLeft: value,
      topRight: value + 1,
      bottomLeft: value + 2,
      bottomRight: value + 3
    )
  }

  private func assertInsets(_ value: Any?, _ expected: [Double]) {
    let insets = value as? [String: Double]
    XCTAssertEqual(insets?["start"], expected[0])
    XCTAssertEqual(insets?["top"], expected[1])
    XCTAssertEqual(insets?["end"], expected[2])
    XCTAssertEqual(insets?["bottom"], expected[3])
  }

  private func assertRadii(_ value: Any?, _ expected: [Double]) {
    let radii = value as? [String: Double]
    XCTAssertEqual(radii?["topLeft"], expected[0])
    XCTAssertEqual(radii?["topRight"], expected[1])
    XCTAssertEqual(radii?["bottomLeft"], expected[2])
    XCTAssertEqual(radii?["bottomRight"], expected[3])
  }

  private func assertUnavailablePayload(_ layout: [String: Any]?) {
    XCTAssertEqual(layout?["schemaVersion"] as? Int, 4)
    XCTAssertEqual(layout?["isAvailable"] as? Bool, false)
    XCTAssertEqual(layout?["isPad"] as? Bool, false)
    XCTAssertEqual(layout?["isFullScreen"] as? Bool, true)
    for field in [
      "baseMargins", "horizontalMargins", "verticalMargins", "baseSafeArea",
      "horizontalSafeArea", "verticalSafeArea",
    ] {
      assertInsets(layout?[field], [0, 0, 0, 0])
    }
    assertRadii(layout?["effectiveCornerRadii"], [0, 0, 0, 0])
  }
}
