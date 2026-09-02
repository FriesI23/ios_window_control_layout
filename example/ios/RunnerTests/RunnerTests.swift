import Flutter
import UIKit
import XCTest

@testable import ios_window_control_layout

class RunnerTests: XCTestCase {
  func testMissingViewReturnsStableError() {
    let plugin = IosWindowControlLayoutPlugin()
    let call = FlutterMethodCall(methodName: "queryLayout", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called")
    plugin.handle(call) { result in
      let error = result as? FlutterError
      XCTAssertEqual(error?.code, "view_unavailable")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testUnavailablePayloadPreservesDeviceAndWindowState() {
    assertUnavailablePayload(
      LayoutPayload.layoutRegionsUnavailable(
        isPad: true,
        isFullScreen: false
      ).encode(),
      isPad: true,
      isFullScreen: false
    )
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
      layoutDirection: .leftToRight,
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
    XCTAssertEqual(payload.baseMargins.left, 2)
    XCTAssertEqual(payload.horizontalMargins.top, 5)
    XCTAssertEqual(payload.verticalMargins.right, 12)
    XCTAssertEqual(payload.baseSafeArea.bottom, 15)
    XCTAssertEqual(payload.horizontalSafeArea.left, 18)
    XCTAssertEqual(payload.verticalSafeArea.right, 24)
    XCTAssertEqual(payload.effectiveCornerRadii.bottomRight, 28)
  }

  func testEncodedPayloadHasCorrectFieldsAndPhysicalValues() {
    let layout = IosWindowControlLayoutPlugin.queryLayout(
      isPad: true,
      isFullScreen: false,
      layoutDirection: .leftToRight,
      baseMargins: insets(1),
      horizontalMargins: insets(5),
      verticalMargins: insets(9),
      baseSafeArea: insets(13),
      horizontalSafeArea: insets(17),
      verticalSafeArea: insets(21),
      effectiveCornerRadii: radii(25)
    ).encode()

    XCTAssertEqual(layout["schemaVersion"] as? Int, 5)
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

  func testDirectionalInsetsBecomePhysicalInBothLayoutDirections() {
    let directional = NSDirectionalEdgeInsets(
      top: 1,
      leading: 10,
      bottom: 2,
      trailing: 20
    )

    let leftToRight = PhysicalInsetsPayload(
      directional,
      layoutDirection: .leftToRight
    )
    XCTAssertEqual(leftToRight.left, 10)
    XCTAssertEqual(leftToRight.right, 20)

    let rightToLeft = PhysicalInsetsPayload(
      directional,
      layoutDirection: .rightToLeft
    )
    XCTAssertEqual(rightToLeft.left, 20)
    XCTAssertEqual(rightToLeft.right, 10)
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
    XCTAssertEqual(insets?["left"], expected[0])
    XCTAssertEqual(insets?["top"], expected[1])
    XCTAssertEqual(insets?["right"], expected[2])
    XCTAssertEqual(insets?["bottom"], expected[3])
  }

  private func assertRadii(_ value: Any?, _ expected: [Double]) {
    let radii = value as? [String: Double]
    XCTAssertEqual(radii?["topLeft"], expected[0])
    XCTAssertEqual(radii?["topRight"], expected[1])
    XCTAssertEqual(radii?["bottomLeft"], expected[2])
    XCTAssertEqual(radii?["bottomRight"], expected[3])
  }

  private func assertUnavailablePayload(
    _ layout: [String: Any]?,
    isPad: Bool,
    isFullScreen: Bool
  ) {
    XCTAssertEqual(layout?["schemaVersion"] as? Int, 5)
    XCTAssertEqual(layout?["isAvailable"] as? Bool, false)
    XCTAssertEqual(layout?["isPad"] as? Bool, isPad)
    XCTAssertEqual(layout?["isFullScreen"] as? Bool, isFullScreen)
    for field in [
      "baseMargins", "horizontalMargins", "verticalMargins", "baseSafeArea",
      "horizontalSafeArea", "verticalSafeArea",
    ] {
      assertInsets(layout?[field], [0, 0, 0, 0])
    }
    assertRadii(layout?["effectiveCornerRadii"], [0, 0, 0, 0])
  }
}
