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
      if #available(iOS 26.0, *) {
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "view_unavailable")
      } else {
        let layout = result as? [String: Any]
        XCTAssertEqual(layout?["isAvailable"] as? Bool, false)
      }
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testPureQueryUsesDirectionalEdges() {
    let payload = IosWindowControlLayoutPlugin.queryLayout(
      baseMargins: NSDirectionalEdgeInsets(
        top: 1,
        leading: 2,
        bottom: 3,
        trailing: 4
      ),
      horizontalMargins: .zero,
      verticalMargins: .zero
    )
    let layout = payload.encode()

    XCTAssertEqual(layout["isAvailable"] as? Bool, true)
    let base = layout["baseMargins"] as? [String: Double]
    XCTAssertEqual(base?["start"], 2)
    XCTAssertEqual(base?["top"], 1)
    XCTAssertEqual(base?["end"], 4)
    XCTAssertEqual(base?["bottom"], 3)
  }
}
