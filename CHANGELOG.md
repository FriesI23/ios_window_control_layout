# Changelog

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
