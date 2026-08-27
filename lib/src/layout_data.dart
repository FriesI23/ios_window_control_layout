import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Layout margins and safe-area regions reported for the current Flutter view.
///
/// Adapted margins and safe areas are raw values from UIKit. The avoidance
/// getters expose only the additional space introduced by corner adaptation,
/// so applications can add that space to an existing baseline without
/// counting it twice.
@immutable
final class IosWindowControlLayoutData {
  /// Creates an immutable layout snapshot.
  const IosWindowControlLayoutData({
    required this.isAvailable,
    required this.baseMargins,
    required this.horizontalMargins,
    required this.verticalMargins,
    this.baseSafeArea = EdgeInsetsDirectional.zero,
    this.horizontalSafeArea = EdgeInsetsDirectional.zero,
    this.verticalSafeArea = EdgeInsetsDirectional.zero,
  });

  /// A snapshot for unsupported platforms and iOS versions before iOS 26.
  static const zero = IosWindowControlLayoutData(
    isAvailable: false,
    baseMargins: EdgeInsetsDirectional.zero,
    horizontalMargins: EdgeInsetsDirectional.zero,
    verticalMargins: EdgeInsetsDirectional.zero,
    baseSafeArea: EdgeInsetsDirectional.zero,
    horizontalSafeArea: EdgeInsetsDirectional.zero,
    verticalSafeArea: EdgeInsetsDirectional.zero,
  );

  /// Whether UIKit layout regions are available for the current view.
  final bool isAvailable;

  /// The view's ordinary directional layout margins.
  final EdgeInsetsDirectional baseMargins;

  /// Margins adapted along the horizontal axis.
  final EdgeInsetsDirectional horizontalMargins;

  /// Margins adapted along the vertical axis.
  final EdgeInsetsDirectional verticalMargins;

  /// The view's ordinary directional safe-area insets.
  ///
  /// Use this raw UIKit value directly when a control should remain inside the
  /// standard safe area near a device or window corner.
  final EdgeInsetsDirectional baseSafeArea;

  /// Safe-area insets adapted along the horizontal axis.
  ///
  /// This is the raw UIKit layout region and can be used directly as layout
  /// padding for floating controls near horizontally curved corners.
  final EdgeInsetsDirectional horizontalSafeArea;

  /// Safe-area insets adapted along the vertical axis.
  ///
  /// This is the raw UIKit layout region and can be used directly as layout
  /// padding for floating controls near vertically curved corners.
  final EdgeInsetsDirectional verticalSafeArea;

  /// Extra directional insets needed for horizontal corner adaptation.
  EdgeInsetsDirectional get horizontalAvoidance =>
      _difference(horizontalMargins, baseMargins);

  /// Extra directional insets needed for vertical corner adaptation.
  EdgeInsetsDirectional get verticalAvoidance =>
      _difference(verticalMargins, baseMargins);

  /// Extra directional insets added by horizontal safe-area adaptation.
  ///
  /// Each edge is `horizontalSafeArea - baseSafeArea`, clamped to zero. This
  /// is an addition to an existing ordinary safe area, not a replacement for
  /// the raw adapted safe-area value.
  EdgeInsetsDirectional get horizontalSafeAreaAvoidance =>
      _difference(horizontalSafeArea, baseSafeArea);

  /// Extra directional insets added by vertical safe-area adaptation.
  ///
  /// Each edge is `verticalSafeArea - baseSafeArea`, clamped to zero. This is
  /// an addition to an existing ordinary safe area, not a replacement for the
  /// raw adapted safe-area value.
  EdgeInsetsDirectional get verticalSafeAreaAvoidance =>
      _difference(verticalSafeArea, baseSafeArea);

  /// Whether either adaptation axis adds any extra margin.
  bool get hasAvoidance =>
      horizontalAvoidance != EdgeInsetsDirectional.zero ||
      verticalAvoidance != EdgeInsetsDirectional.zero;

  static EdgeInsetsDirectional _difference(
    EdgeInsetsDirectional adapted,
    EdgeInsetsDirectional base,
  ) => EdgeInsetsDirectional.fromSTEB(
    math.max(0, adapted.start - base.start),
    math.max(0, adapted.top - base.top),
    math.max(0, adapted.end - base.end),
    math.max(0, adapted.bottom - base.bottom),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IosWindowControlLayoutData &&
          other.isAvailable == isAvailable &&
          other.baseMargins == baseMargins &&
          other.horizontalMargins == horizontalMargins &&
          other.verticalMargins == verticalMargins &&
          other.baseSafeArea == baseSafeArea &&
          other.horizontalSafeArea == horizontalSafeArea &&
          other.verticalSafeArea == verticalSafeArea;

  @override
  int get hashCode => Object.hash(
    isAvailable,
    baseMargins,
    horizontalMargins,
    verticalMargins,
    baseSafeArea,
    horizontalSafeArea,
    verticalSafeArea,
  );

  @override
  String toString() =>
      'IosWindowControlLayoutData('
      'isAvailable: $isAvailable, '
      'baseMargins: $baseMargins, '
      'horizontalMargins: $horizontalMargins, '
      'verticalMargins: $verticalMargins, '
      'baseSafeArea: $baseSafeArea, '
      'horizontalSafeArea: $horizontalSafeArea, '
      'verticalSafeArea: $verticalSafeArea)';
}
