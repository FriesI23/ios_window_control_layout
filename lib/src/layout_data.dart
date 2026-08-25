import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Layout margins reported by UIKit for the current Flutter view.
///
/// The adapted margins are raw values from UIKit. The avoidance getters expose
/// only the additional space introduced by corner adaptation, so applications
/// can add that space to their existing layout margins without counting the
/// baseline twice.
@immutable
final class IosWindowControlLayoutData {
  /// Creates an immutable layout snapshot.
  const IosWindowControlLayoutData({
    required this.isAvailable,
    required this.baseMargins,
    required this.horizontalMargins,
    required this.verticalMargins,
  });

  /// A snapshot for unsupported platforms and iOS versions before iOS 26.
  static const zero = IosWindowControlLayoutData(
    isAvailable: false,
    baseMargins: EdgeInsetsDirectional.zero,
    horizontalMargins: EdgeInsetsDirectional.zero,
    verticalMargins: EdgeInsetsDirectional.zero,
  );

  /// Whether UIKit layout regions are available for the current view.
  final bool isAvailable;

  /// The view's ordinary directional layout margins.
  final EdgeInsetsDirectional baseMargins;

  /// Margins adapted along the horizontal axis.
  final EdgeInsetsDirectional horizontalMargins;

  /// Margins adapted along the vertical axis.
  final EdgeInsetsDirectional verticalMargins;

  /// Extra directional insets needed for horizontal corner adaptation.
  EdgeInsetsDirectional get horizontalAvoidance =>
      _difference(horizontalMargins, baseMargins);

  /// Extra directional insets needed for vertical corner adaptation.
  EdgeInsetsDirectional get verticalAvoidance =>
      _difference(verticalMargins, baseMargins);

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
          other.verticalMargins == verticalMargins;

  @override
  int get hashCode =>
      Object.hash(isAvailable, baseMargins, horizontalMargins, verticalMargins);

  @override
  String toString() =>
      'IosWindowControlLayoutData('
      'isAvailable: $isAvailable, '
      'baseMargins: $baseMargins, '
      'horizontalMargins: $horizontalMargins, '
      'verticalMargins: $verticalMargins)';
}
