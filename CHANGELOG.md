# Changelog

## 0.6.0

> **Breaking change:** Wire schema v6 strictly rejects schema v5 payloads.
> Rebuild the iOS app when upgrading so the Dart and native plugin versions
> stay in sync.

- Add active system occlusion geometry and optional vertical-bar layout guidance
  on iOS/iPadOS 27.1+.
- Refresh occlusion data automatically as the native layout changes.
- Clear stale occlusion data when the Flutter view changes or a query fails.
- Add an occlusion diagnostic overlay to the example.

## 0.5.0

> **Breaking change:** Layout margins, safe areas, and avoidance values now use
> physical `EdgeInsets`. Replace `start`/`end` access with `left`/`right` and do
> not resolve these values against Flutter's `Directionality`. Wire schema v5
> strictly rejects schema v4 payloads.

- Report layout margins, safe areas, and avoidance as physical `EdgeInsets`
  whose left and right sides do not flip with Flutter's text direction.
- Resolve UIKit's directional layout regions with the root view's effective
  interface direction and upgrade the native wire payload to schema version 5.
- Add an RTL example and migration guidance for assigning physical avoidance
  to Flutter's logical leading and trailing controls.

## 0.4.1

- Preserve the current UIKit interface idiom and window state on iOS versions
  before 26 while keeping unavailable layout-region values at zero.
- Select the supported window-scene coordinate-space API for iOS 13–25 and
  iOS 26 or later without calling newer layout APIs on older systems.

## 0.4.0

- Expose the current UIKit interface idiom and whether the iPadOS scene
  exactly covers its screen coordinate space.
- Distinguish iPad window-control avoidance from ordinary device corner
  adaptation.
- Upgrade the native wire payload to schema version 4.

## 0.3.0

- Expose the current UIKit view's physical effective corner radii on iOS 26.
- Upgrade the native wire payload to schema version 3.

## 0.2.0

- Add iOS 26 corner-adapted safe-area layout regions and directional
  safe-area avoidance values.
- Upgrade the native wire payload to schema version 2 while preserving the
  existing margin APIs and refresh behavior.

## 0.1.1

- Improve the Material and Cupertino examples with an opt-out comparison
  switch and correct toolbar spacing.
- Add before-and-after screenshots and a Chinese README.

## 0.1.0

- Add iOS 26 corner-adapted margin queries backed by `UIView.LayoutRegion`.
- Add directional horizontal and vertical avoidance data.
- Add a layout widget that refreshes on window and lifecycle changes.
- Support Swift Package Manager and CocoaPods from one Swift source tree.
- Add a Material/Cupertino AppBar example with live avoidance visualization.
