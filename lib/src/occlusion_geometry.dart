import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Active system occlusions in the current Flutter view's logical coordinates.
///
/// This geometry is independent of `IosWindowControlLayoutData.isAvailable`.
/// A non-null snapshot with no active regions is a successful query, not an
/// unavailable result. Regions may extend beyond [viewBounds]; consumers must
/// intersect them with their local layout.
@immutable
final class IosOcclusionGeometry {
  /// Copies [activeOcclusionRegions] into an immutable list.
  IosOcclusionGeometry({
    required this.viewBounds,
    required List<Rect> activeOcclusionRegions,
    required this.hasVerticalSystemBar,
    this.verticalBarLayoutFrame,
  }) : activeOcclusionRegions = List<Rect>.unmodifiable(activeOcclusionRegions);

  /// Bounds of the Flutter view in the same coordinate space as the regions.
  final Rect viewBounds;

  /// Physical active occlusions; left and right never flip for Flutter RTL.
  final List<Rect> activeOcclusionRegions;

  /// Whether UIKit reports a vertical system-bar edge for this context.
  ///
  /// This describes the context's vertical-bar preference or capability. It
  /// does not guarantee that a system bar is currently visible, nor is its
  /// edge a rectangle that applications should reserve in full.
  final bool hasVerticalSystemBar;

  /// UIKit's recommended vertical bar layout region, in Flutter-view points.
  ///
  /// This optional region provides a physical center line for controls. It is
  /// not the frame of a Wi-Fi icon or an additional occlusion. Missing or
  /// unavailable layout-region capabilities leave this null while the active
  /// occlusion query can remain valid.
  final Rect? verticalBarLayoutFrame;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IosOcclusionGeometry &&
          other.viewBounds == viewBounds &&
          listEquals(other.activeOcclusionRegions, activeOcclusionRegions) &&
          other.hasVerticalSystemBar == hasVerticalSystemBar &&
          other.verticalBarLayoutFrame == verticalBarLayoutFrame;

  @override
  int get hashCode => Object.hash(
    viewBounds,
    Object.hashAll(activeOcclusionRegions),
    hasVerticalSystemBar,
    verticalBarLayoutFrame,
  );

  @override
  String toString() =>
      'IosOcclusionGeometry('
      'viewBounds: $viewBounds, '
      'activeOcclusionRegions: $activeOcclusionRegions, '
      'hasVerticalSystemBar: $hasVerticalSystemBar, '
      'verticalBarLayoutFrame: $verticalBarLayoutFrame)';
}
