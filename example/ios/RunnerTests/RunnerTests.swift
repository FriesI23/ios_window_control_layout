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

    XCTAssertEqual(layout["schemaVersion"] as? Int, 6)
    XCTAssertEqual(layout["isAvailable"] as? Bool, true)
    XCTAssertEqual(layout["isPad"] as? Bool, true)
    XCTAssertEqual(layout["isFullScreen"] as? Bool, false)
    XCTAssertEqual(
      Set(layout.keys),
      Set([
        "schemaVersion", "isAvailable", "isPad", "isFullScreen",
        "baseMargins", "horizontalMargins", "verticalMargins", "baseSafeArea",
        "horizontalSafeArea", "verticalSafeArea", "effectiveCornerRadii",
        "occlusionGeometry",
      ]))
    XCTAssertTrue(layout["occlusionGeometry"] is NSNull)
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

  func testOcclusionPayloadPreservesNegativeFramesAndDistinguishesEmptyFromUnavailable() {
    let negativeFrame = CGRect(x: -8, y: -4, width: 70, height: 40)
    let bounds = CGRect(x: 0, y: 0, width: 700, height: 600)
    let geometry = OcclusionGeometryPayload(
      viewBounds: bounds,
      activeOcclusionRegions: [negativeFrame],
      hasVerticalSystemBar: true,
      verticalBarLayoutFrame: CGRect(x: 630, y: 124, width: 44, height: 442)
    ).encode()

    XCTAssertEqual(
      geometry["viewBounds"] as? [String: Double],
      [
        "x": 0, "y": 0, "width": 700, "height": 600,
      ])
    XCTAssertEqual(
      geometry["activeOcclusionRegions"] as? [[String: Double]],
      [
        [
          "x": -8, "y": -4, "width": 70, "height": 40,
        ]
      ])
    XCTAssertEqual(geometry["hasVerticalSystemBar"] as? Bool, true)
    XCTAssertEqual(
      geometry["verticalBarLayoutFrame"] as? [String: Double],
      [
        "x": 630, "y": 124, "width": 44, "height": 442,
      ])

    var payload = LayoutPayload.layoutRegionsUnavailable(isPad: false, isFullScreen: true)
    XCTAssertTrue(payload.encode()["occlusionGeometry"] is NSNull)
    payload.occlusionGeometry = OcclusionGeometryPayload(
      viewBounds: bounds,
      activeOcclusionRegions: [],
      hasVerticalSystemBar: false
    )
    let empty = payload.encode()["occlusionGeometry"] as? [String: Any]
    XCTAssertNotNil(empty)
    XCTAssertTrue(empty?["verticalBarLayoutFrame"] is NSNull)
    XCTAssertEqual((empty?["activeOcclusionRegions"] as? [[String: Double]])?.count, 0)
  }

  func testRegionObserverDeduplicatesRefreshAndInvalidatesWhenRootDetaches() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires reserved regions") }
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    var regions = [CGRect(x: 620, y: -4, width: 90, height: 40)]
    var notifications = 0
    var reads = 0
    let observer = ReservedRegionObserver(
      rootView: root,
      geometryReader: { view, rootView in
        reads += 1
        XCTAssertEqual(view.frame, rootView.bounds)
        return OcclusionGeometryPayload(
          viewBounds: rootView.bounds,
          activeOcclusionRegions: regions,
          hasVerticalSystemBar: true
        )
      },
      onChange: { notifications += 1 }
    )
    defer { observer.detach() }
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(observer.geometry?.activeOcclusionRegions, regions)
    XCTAssertEqual(notifications, 1)
    XCTAssertFalse(observer.isUserInteractionEnabled)
    XCTAssertTrue(observer.accessibilityElementsHidden)

    observer.refresh()
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(notifications, 1, "An unchanged query must not start a refresh loop")
    XCTAssertEqual(reads, 1, "An unchanged refresh must not request another constraints pass")

    regions = []
    // Model UIKit scheduling its tracked read after a reserved-region change.
    observer.setNeedsUpdateConstraints()
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(observer.geometry?.activeOcclusionRegions, [])
    XCTAssertEqual(notifications, 2)

    root.removeFromSuperview()
    XCTAssertNil(observer.geometry)
    XCTAssertEqual(notifications, 3)

    root.frame = CGRect(x: 0, y: 0, width: 600, height: 700)
    window.addSubview(root)
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(observer.geometry?.viewBounds, root.bounds)
    XCTAssertEqual(observer.bounds.size, root.bounds.size)
    XCTAssertEqual(notifications, 4)
  }

  func testObserverRefreshesResizedSnapshotAfterAutoresizingHasUpdatedFrame() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires reserved regions") }
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    var reads = 0
    let observer = ReservedRegionObserver(
      rootView: root,
      geometryReader: { _, rootView in
        reads += 1
        return OcclusionGeometryPayload(
          viewBounds: rootView.bounds,
          activeOcclusionRegions: [],
          hasVerticalSystemBar: true
        )
      },
      onChange: {}
    )
    defer { observer.detach() }
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(reads, 1)

    root.bounds.size = CGSize(width: 600, height: 700)
    // UIKit can resize the observer before its layout callback sees the old
    // snapshot. A matching frame must not suppress reading the new bounds.
    observer.frame = root.bounds
    observer.refresh()
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(reads, 2)
    XCTAssertEqual(observer.geometry?.viewBounds, root.bounds)

    observer.refresh()
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(reads, 2)
  }

  func testOcclusionEventsCoalesceAndRootReplacementInvalidates() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires reserved regions") }
    let plugin = IosWindowControlLayoutPlugin()
    defer { plugin.detachOcclusionObservation() }
    var events: [Int] = []
    XCTAssertNil(
      plugin.onListen(withArguments: nil) { event in
        if let sequence = event as? Int { events.append(sequence) }
      })
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let firstRoot = UIView(frame: window.bounds)
    window.addSubview(firstRoot)
    plugin.synchronizeOcclusionObserver(with: firstRoot)
    firstRoot.layoutIfNeeded()
    let initialObserver = try XCTUnwrap(firstRoot.subviews.first { $0 is ReservedRegionObserver })
    XCTAssertFalse(firstRoot.layer.needsLayout())
    XCTAssertFalse(initialObserver.layer.needsLayout())
    plugin.synchronizeOcclusionObserver(with: firstRoot)
    XCTAssertFalse(
      firstRoot.layer.needsLayout(), "An unchanged query must not dirty the Flutter root")
    XCTAssertFalse(
      initialObserver.layer.needsLayout(), "An unchanged query must not dirty its observer")
    firstRoot.layoutIfNeeded()

    let initialEvent = expectation(description: "Coalesced first snapshot")
    DispatchQueue.main.async {
      XCTAssertEqual(events.count, 1)
      let replacement = UIView(frame: window.bounds)
      window.addSubview(replacement)
      plugin.synchronizeOcclusionObserver(with: replacement)
      XCTAssertNil(plugin.occlusionGeometry, "A replaced root must not expose old geometry")
      replacement.layoutIfNeeded()
      DispatchQueue.main.async {
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events, [1, 2])
        plugin.synchronizeOcclusionObserver(with: nil)
        XCTAssertNil(plugin.occlusionGeometry)
        XCTAssertNil(plugin.onCancel(withArguments: nil))
        initialEvent.fulfill()
      }
    }
    waitForExpectations(timeout: 2)
  }

  @MainActor
  func testCancellingOcclusionEventsPreservesQueryableGeometry() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires occlusion tracking") }
    let plugin = IosWindowControlLayoutPlugin()
    defer { plugin.detachOcclusionObservation() }
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    let initialGeometry = OcclusionGeometryPayload(
      viewBounds: root.bounds,
      activeOcclusionRegions: [CGRect(x: 620, y: 0, width: 80, height: 60)],
      hasVerticalSystemBar: true
    )
    weak var observer: TestOcclusionObserver?
    var creations = 0
    plugin.occlusionObserverFactory = { view, onChange in
      creations += 1
      let next = TestOcclusionObserver(
        rootView: view, geometry: initialGeometry, onChange: onChange)
      observer = next
      return next
    }
    var events = 0
    XCTAssertNil(plugin.onListen(withArguments: nil) { _ in events += 1 })
    plugin.synchronizeOcclusionObserver(with: root)
    XCTAssertEqual(plugin.occlusionGeometry, initialGeometry)

    XCTAssertNil(plugin.onCancel(withArguments: nil))
    XCTAssertNotNil(observer, "Queries still need the observer after event cancellation")
    plugin.synchronizeOcclusionObserver(with: root)
    XCTAssertEqual(creations, 1)
    XCTAssertEqual(plugin.occlusionGeometry, initialGeometry)
    let nextGeometry = OcclusionGeometryPayload(
      viewBounds: root.bounds, activeOcclusionRegions: [], hasVerticalSystemBar: true)
    observer?.updateGeometry(nextGeometry)
    XCTAssertEqual(plugin.occlusionGeometry, nextGeometry)

    let cancelled = expectation(description: "No queued events reach the cancelled listener")
    DispatchQueue.main.async {
      XCTAssertEqual(events, 0)
      XCTAssertEqual(plugin.occlusionGeometry, nextGeometry)
      cancelled.fulfill()
    }
    waitForExpectations(timeout: 2)
  }

  @MainActor
  func testDetachingOcclusionObservationReleasesObserverAndStopsQueuedChanges() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires occlusion tracking") }
    let plugin = IosWindowControlLayoutPlugin()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    let geometry = OcclusionGeometryPayload(
      viewBounds: root.bounds, activeOcclusionRegions: [], hasVerticalSystemBar: false)
    weak var observer: TestOcclusionObserver?
    var staleChange: (() -> Void)?
    var creations = 0
    var detachments = 0
    plugin.occlusionObserverFactory = { view, onChange in
      creations += 1
      staleChange = onChange
      let next = TestOcclusionObserver(
        rootView: view, geometry: geometry, onChange: onChange,
        onDetach: { detachments += 1 })
      observer = next
      return next
    }
    var events: [Int] = []
    XCTAssertNil(
      plugin.onListen(withArguments: nil) { event in
        if let sequence = event as? Int { events.append(sequence) }
      })
    plugin.synchronizeOcclusionObserver(with: root)
    XCTAssertNotNil(observer)

    // Detach before the initial invalidation has left the main queue.
    plugin.detachOcclusionObservation()
    XCTAssertEqual(events.count, 1, "Detach sends one final invalidation")
    XCTAssertEqual(detachments, 1)
    XCTAssertNil(observer, "The plugin must release its observer")
    XCTAssertNil(plugin.occlusionGeometry)
    staleChange?()
    plugin.synchronizeOcclusionObserver(with: root)

    let detached = expectation(description: "Pending and subsequent changes stay detached")
    DispatchQueue.main.async {
      staleChange?()
      plugin.synchronizeOcclusionObserver(with: root)
      DispatchQueue.main.async {
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(creations, 1, "A detached plugin must not attach another observer")
        XCTAssertNil(plugin.occlusionGeometry)
        detached.fulfill()
      }
    }
    waitForExpectations(timeout: 2)
  }

  @MainActor
  func testAvailableRuntimeCapabilitiesReadSystemRegions() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires runtime capabilities") }
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    let kindSelector = NSSelectorFromString("occlusionRegionKind")
    let traitsSelector = NSSelectorFromString("systemTraitsAffectingVerticalBarEdge")
    let kindType = NSClassFromString("UIViewReservedRegionKind") as? NSObject.Type
    let traits =
      UITraitCollection.responds(to: traitsSelector)
      ? UITraitCollection.perform(traitsSelector)?.takeUnretainedValue() as? NSArray : nil
    let details =
      "kind=\(String(describing: kindType)); kindGetter=\(kindType?.responds(to: kindSelector) ?? false); traits=\(String(describing: traits)); query=\(root.responds(to: NSSelectorFromString("reservedRegionsOfKind:"))); edge=\(root.traitCollection.responds(to: NSSelectorFromString("verticalBarEdge")))"
    let capabilities = try XCTUnwrap(ReservedRegionCapabilities.resolve(for: root), details)
    let observer = ReservedRegionObserver(rootView: root, capabilities: capabilities, onChange: {})
    defer { observer.detach() }
    XCTAssertTrue(observer.isObserving, details)
    observer.updateConstraintsIfNeeded()
    let geometry = try XCTUnwrap(observer.geometry, details)
    XCTAssertEqual(geometry.viewBounds, root.bounds)
  }

  @MainActor
  func testBarFactoryChecksScalarSignatureAndResolvesOnce() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires bar regions") }
    BarRegionScalarFactory.inputs = []
    XCTAssertNotNil(
      VerticalBarLayoutCapabilities.resolve(classLookup: { _ in BarRegionScalarFactory.self }))
    XCTAssertEqual(BarRegionScalarFactory.inputs.count, 2)
    XCTAssertEqual(
      BarRegionScalarFactory.inputs.map(\.0), [UIRectEdge.left.rawValue, UIRectEdge.right.rawValue])
    XCTAssertEqual(BarRegionScalarFactory.inputs.map(\.1), [44, 44])
    XCTAssertNil(VerticalBarLayoutCapabilities.resolve(classLookup: { _ in nil }))
    XCTAssertNil(
      VerticalBarLayoutCapabilities.resolve(classLookup: { _ in BarRegionObjectFactory.self }))
  }

  @MainActor
  func testMissingBarCapabilityKeepsCoreOcclusionQueryAvailable() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires reserved regions") }
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    let capabilities = try XCTUnwrap(
      ReservedRegionCapabilities.resolve(
        for: root,
        classLookup: {
          $0 == "UIViewLayoutRegion" ? nil : NSClassFromString($0) as? NSObject.Type
        }))
    let geometry = try XCTUnwrap(capabilities.read(from: root, rootView: root))
    XCTAssertEqual(geometry.viewBounds, root.bounds)
    XCTAssertNil(geometry.verticalBarLayoutFrame)
  }

  @MainActor
  func testPublicBarLayoutRegionReusesItsLayoutGuide() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires bar regions") }
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    let capability = try XCTUnwrap(VerticalBarLayoutCapabilities.resolve())
    _ = capability.read(from: root, rootView: root, verticalEdge: 2)
    let count = root.layoutGuides.count
    for _ in 0..<8 {
      _ = capability.read(from: root, rootView: root, verticalEdge: 2)
    }
    XCTAssertEqual(root.layoutGuides.count, count)
    XCTAssertNil(capability.read(from: root, rootView: root, verticalEdge: 0))
    XCTAssertNil(capability.read(from: root, rootView: root, verticalEdge: 9))
  }

  @MainActor
  func testMissingCapabilitiesDoNotAttachAnObserverOrInvalidateRepeatedQueries() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires capability probing") }
    let plugin = IosWindowControlLayoutPlugin()
    defer { plugin.detachOcclusionObservation() }
    plugin.occlusionObserverFactory = { _, _ in nil }
    var events = 0
    XCTAssertNil(plugin.onListen(withArguments: nil) { _ in events += 1 })
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    XCTAssertNil(ReservedRegionCapabilities.resolve(for: root, classLookup: { _ in nil }))
    for _ in 0..<3 {
      plugin.synchronizeOcclusionObserver(with: root)
      XCTAssertNil(plugin.occlusionGeometry)
      XCTAssertTrue(root.subviews.isEmpty)
    }
    let initialEvent = expectation(description: "Only the initial event")
    DispatchQueue.main.async {
      XCTAssertEqual(events, 1)
      plugin.synchronizeOcclusionObserver(with: root)
      DispatchQueue.main.async {
        XCTAssertEqual(events, 1, "A fallback query must not create a refresh loop")
        initialEvent.fulfill()
      }
    }
    waitForExpectations(timeout: 2)
  }

  func testFailedRegionReadInvalidatesPreviousGeometryAndCanRecoverEmpty() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires reserved regions") }
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 700, height: 600))
    let root = UIView(frame: window.bounds)
    window.addSubview(root)
    var snapshot: OcclusionGeometryPayload? = OcclusionGeometryPayload(
      viewBounds: root.bounds,
      activeOcclusionRegions: [CGRect(x: 620, y: 0, width: 80, height: 60)],
      hasVerticalSystemBar: true
    )
    var notifications = 0
    var reads = 0
    let observer = ReservedRegionObserver(
      rootView: root,
      geometryReader: { _, _ in
        reads += 1
        return snapshot
      },
      onChange: { notifications += 1 }
    )
    defer { observer.detach() }
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(observer.geometry, snapshot)
    snapshot = nil
    observer.setNeedsUpdateConstraints()
    observer.updateConstraintsIfNeeded()
    XCTAssertNil(observer.geometry)
    XCTAssertEqual(notifications, 2)
    XCTAssertEqual(reads, 2)
    for _ in 0..<3 {
      observer.setNeedsLayout()
      observer.layoutIfNeeded()
      observer.refresh()
      observer.updateConstraintsIfNeeded()
    }
    XCTAssertEqual(reads, 2, "An unavailable snapshot must not cause layout polling")
    snapshot = OcclusionGeometryPayload(
      viewBounds: root.bounds, activeOcclusionRegions: [], hasVerticalSystemBar: true
    )
    observer.setNeedsUpdateConstraints()
    observer.updateConstraintsIfNeeded()
    XCTAssertEqual(observer.geometry?.activeOcclusionRegions, [])
    XCTAssertEqual(notifications, 3)
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
    XCTAssertEqual(layout?["schemaVersion"] as? Int, 6)
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
    XCTAssertTrue(layout?["occlusionGeometry"] is NSNull)
  }
}

private final class TestOcclusionObserver: OcclusionGeometryObserving {
  private(set) weak var rootView: UIView?
  private(set) var geometry: OcclusionGeometryPayload?
  private var onChange: (() -> Void)?
  private let onDetach: () -> Void

  init(
    rootView: UIView,
    geometry: OcclusionGeometryPayload?,
    onChange: @escaping () -> Void,
    onDetach: @escaping () -> Void = {}
  ) {
    self.rootView = rootView
    self.geometry = geometry
    self.onChange = onChange
    self.onDetach = onDetach
  }

  func refresh() {}

  func updateGeometry(_ next: OcclusionGeometryPayload?) {
    geometry = next
    onChange?()
  }

  func detach() {
    updateGeometry(nil)
    onChange = nil
    rootView = nil
    onDetach()
  }
}

@MainActor
@objc private final class BarRegionScalarFactory: NSObject {
  static var inputs: [(UInt, CGFloat)] = []

  @objc(layoutRegionForBarOnEdge:extent:)
  static func make(edge: UInt, extent: CGFloat) -> NSObject {
    inputs.append((edge, extent))
    return NSObject()
  }
}

@objc private final class BarRegionObjectFactory: NSObject {
  @objc(layoutRegionForBarOnEdge:extent:)
  static func make(edge: NSNumber, extent: NSNumber) -> NSObject {
    NSObject()
  }
}
