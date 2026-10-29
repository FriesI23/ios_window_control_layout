// Wire payloads mirrored by the native LayoutPayload.swift implementation.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'layout_data.dart';
import 'occlusion_geometry.dart';

/// Physical insets in the native wire payload.
///
/// Keep this structure synchronized with Swift's `PhysicalInsetsPayload`.
final class PhysicalInsetsPayload {
  const PhysicalInsetsPayload({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory PhysicalInsetsPayload.decode(Object? value, String field) {
    final map = _expectMap(value, field);

    double number(String edge) {
      final value = map[edge];
      if (value is! num || !value.isFinite) {
        throw _invalidData('Expected $field.$edge to be a finite number.');
      }
      return value.toDouble();
    }

    return PhysicalInsetsPayload(
      left: number('left'),
      top: number('top'),
      right: number('right'),
      bottom: number('bottom'),
    );
  }

  final double left;
  final double top;
  final double right;
  final double bottom;

  EdgeInsets toInsets() => EdgeInsets.fromLTRB(left, top, right, bottom);
}

/// Physical corner radii in the native wire payload.
///
/// Keep this structure synchronized with Swift's `CornerRadiiPayload`.
final class CornerRadiiPayload {
  const CornerRadiiPayload({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  factory CornerRadiiPayload.decode(Object? value, String field) {
    final map = _expectMap(value, field);

    double radius(String corner) {
      final value = map[corner];
      if (value is! num || !value.isFinite || value < 0) {
        throw _invalidData(
          'Expected $field.$corner to be a finite non-negative number.',
        );
      }
      return value.toDouble();
    }

    return CornerRadiiPayload(
      topLeft: radius('topLeft'),
      topRight: radius('topRight'),
      bottomLeft: radius('bottomLeft'),
      bottomRight: radius('bottomRight'),
    );
  }

  final double topLeft;
  final double topRight;
  final double bottomLeft;
  final double bottomRight;

  BorderRadius toBorderRadius() => BorderRadius.only(
    topLeft: Radius.circular(topLeft),
    topRight: Radius.circular(topRight),
    bottomLeft: Radius.circular(bottomLeft),
    bottomRight: Radius.circular(bottomRight),
  );
}

/// A physical rectangle in the native wire payload.
///
/// Coordinates may be negative or extend beyond the Flutter view.
final class PhysicalRectPayload {
  const PhysicalRectPayload({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory PhysicalRectPayload.decode(
    Object? value,
    String field, {
    bool requirePositiveSize = false,
  }) {
    final map = _expectMap(value, field);

    double number(String key) {
      final value = map[key];
      if (value is! num || !value.isFinite) {
        throw _invalidData('Expected $field.$key to be a finite number.');
      }
      return value.toDouble();
    }

    final x = number('x');
    final y = number('y');
    final width = number('width');
    final height = number('height');
    if (width < 0 ||
        height < 0 ||
        (requirePositiveSize && (width == 0 || height == 0))) {
      throw _invalidData('Expected valid dimensions for $field.');
    }
    if (!(x + width).isFinite || !(y + height).isFinite) {
      throw _invalidData('Expected finite bounds for $field.');
    }

    return PhysicalRectPayload(x: x, y: y, width: width, height: height);
  }

  final double x;
  final double y;
  final double width;
  final double height;

  Rect toRect() => Rect.fromLTWH(x, y, width, height);
}

/// System occlusions mirrored by Swift's `OcclusionGeometryPayload`.
final class OcclusionGeometryPayload {
  const OcclusionGeometryPayload({
    required this.viewBounds,
    required this.activeOcclusionRegions,
    required this.hasVerticalSystemBar,
    this.verticalBarLayoutFrame,
  });

  factory OcclusionGeometryPayload.decode(Object? value) {
    const field = 'occlusionGeometry';
    final map = _expectMap(value, field);
    final regions = map['activeOcclusionRegions'];
    final hasVerticalSystemBar = map['hasVerticalSystemBar'];
    if (regions is! List<Object?>) {
      throw _invalidData(
        'Expected $field.activeOcclusionRegions to be a list.',
      );
    }
    if (hasVerticalSystemBar is! bool) {
      throw _invalidData(
        'Expected $field.hasVerticalSystemBar to be a boolean.',
      );
    }

    final viewBounds = PhysicalRectPayload.decode(
      map['viewBounds'],
      '$field.viewBounds',
      requirePositiveSize: true,
    );
    final activeOcclusionRegions = [
      for (var index = 0; index < regions.length; index++)
        PhysicalRectPayload.decode(
          regions[index],
          '$field.activeOcclusionRegions[$index]',
        ),
    ];

    // Older schema-6 senders omit this optional alignment capability.
    // Malformed data disables alignment without discarding valid occlusions.
    PhysicalRectPayload? verticalBarLayoutFrame;
    if (map['verticalBarLayoutFrame'] != null) {
      try {
        final frame = PhysicalRectPayload.decode(
          map['verticalBarLayoutFrame'],
          '$field.verticalBarLayoutFrame',
        );
        if (!frame.toRect().isEmpty) verticalBarLayoutFrame = frame;
      } on PlatformException {
        verticalBarLayoutFrame = null;
      }
    }

    return OcclusionGeometryPayload(
      viewBounds: viewBounds,
      activeOcclusionRegions: activeOcclusionRegions,
      hasVerticalSystemBar: hasVerticalSystemBar,
      verticalBarLayoutFrame: verticalBarLayoutFrame,
    );
  }

  final PhysicalRectPayload viewBounds;
  final List<PhysicalRectPayload> activeOcclusionRegions;
  final bool hasVerticalSystemBar;
  final PhysicalRectPayload? verticalBarLayoutFrame;

  IosOcclusionGeometry toGeometry() => IosOcclusionGeometry(
    viewBounds: viewBounds.toRect(),
    activeOcclusionRegions: [
      for (final region in activeOcclusionRegions) region.toRect(),
    ],
    hasVerticalSystemBar: hasVerticalSystemBar,
    verticalBarLayoutFrame: verticalBarLayoutFrame?.toRect(),
  );
}

/// Versioned wire payload transported by [StandardMethodCodec].
///
/// Keep this structure synchronized with Swift's `LayoutPayload`. Encoded
/// values must remain within the types supported by [StandardMessageCodec].
final class LayoutPayload {
  const LayoutPayload({
    required this.isAvailable,
    required this.isPad,
    required this.isFullScreen,
    required this.baseMargins,
    required this.horizontalMargins,
    required this.verticalMargins,
    required this.baseSafeArea,
    required this.horizontalSafeArea,
    required this.verticalSafeArea,
    required this.effectiveCornerRadii,
    required this.occlusionGeometry,
  });

  factory LayoutPayload.decode(Object? value) {
    final map = _expectMap(value, 'payload');
    final version = map[_schemaVersionField];
    if (version is! int || version != schemaVersion) {
      throw _invalidData('Unsupported $_schemaVersionField: $version.');
    }
    final isAvailable = map[_isAvailableField];
    if (isAvailable is! bool) {
      throw _invalidData('Expected a boolean $_isAvailableField value.');
    }
    final isPad = map[_isPadField];
    if (isPad is! bool) {
      throw _invalidData('Expected a boolean $_isPadField value.');
    }
    final isFullScreen = map[_isFullScreenField];
    if (isFullScreen is! bool) {
      throw _invalidData('Expected a boolean $_isFullScreenField value.');
    }

    if (!map.containsKey(_occlusionGeometryField)) {
      throw _invalidData('Missing $_occlusionGeometryField.');
    }

    return LayoutPayload(
      isAvailable: isAvailable,
      isPad: isPad,
      isFullScreen: isFullScreen,
      baseMargins: PhysicalInsetsPayload.decode(
        map[_baseMarginsField],
        _baseMarginsField,
      ),
      horizontalMargins: PhysicalInsetsPayload.decode(
        map[_horizontalMarginsField],
        _horizontalMarginsField,
      ),
      verticalMargins: PhysicalInsetsPayload.decode(
        map[_verticalMarginsField],
        _verticalMarginsField,
      ),
      baseSafeArea: PhysicalInsetsPayload.decode(
        map[_baseSafeAreaField],
        _baseSafeAreaField,
      ),
      horizontalSafeArea: PhysicalInsetsPayload.decode(
        map[_horizontalSafeAreaField],
        _horizontalSafeAreaField,
      ),
      verticalSafeArea: PhysicalInsetsPayload.decode(
        map[_verticalSafeAreaField],
        _verticalSafeAreaField,
      ),
      occlusionGeometry: map[_occlusionGeometryField] == null
          ? null
          : OcclusionGeometryPayload.decode(map[_occlusionGeometryField]),
      effectiveCornerRadii: CornerRadiiPayload.decode(
        map[_effectiveCornerRadiiField],
        _effectiveCornerRadiiField,
      ),
    );
  }

  static const schemaVersion = 6;
  static const _schemaVersionField = 'schemaVersion';
  static const _isAvailableField = 'isAvailable';
  static const _isPadField = 'isPad';
  static const _isFullScreenField = 'isFullScreen';
  static const _baseMarginsField = 'baseMargins';
  static const _horizontalMarginsField = 'horizontalMargins';
  static const _verticalMarginsField = 'verticalMargins';
  static const _baseSafeAreaField = 'baseSafeArea';
  static const _horizontalSafeAreaField = 'horizontalSafeArea';
  static const _verticalSafeAreaField = 'verticalSafeArea';
  static const _effectiveCornerRadiiField = 'effectiveCornerRadii';
  static const _occlusionGeometryField = 'occlusionGeometry';

  final bool isAvailable;
  final bool isPad;
  final bool isFullScreen;
  final PhysicalInsetsPayload baseMargins;
  final PhysicalInsetsPayload horizontalMargins;
  final PhysicalInsetsPayload verticalMargins;
  final PhysicalInsetsPayload baseSafeArea;
  final PhysicalInsetsPayload horizontalSafeArea;
  final PhysicalInsetsPayload verticalSafeArea;
  final CornerRadiiPayload effectiveCornerRadii;
  final OcclusionGeometryPayload? occlusionGeometry;

  IosWindowControlLayoutData toLayoutData() => IosWindowControlLayoutData(
    isAvailable: isAvailable,
    isPad: isPad,
    isFullScreen: isFullScreen,
    baseMargins: baseMargins.toInsets(),
    horizontalMargins: horizontalMargins.toInsets(),
    verticalMargins: verticalMargins.toInsets(),
    baseSafeArea: baseSafeArea.toInsets(),
    horizontalSafeArea: horizontalSafeArea.toInsets(),
    verticalSafeArea: verticalSafeArea.toInsets(),
    effectiveCornerRadii: effectiveCornerRadii.toBorderRadius(),
    occlusionGeometry: occlusionGeometry?.toGeometry(),
  );
}

Map<Object?, Object?> _expectMap(Object? value, String field) {
  if (value is! Map<Object?, Object?>) {
    throw _invalidData('Expected $field to be a map.');
  }
  return value;
}

PlatformException _invalidData(String message) =>
    PlatformException(code: 'invalid_data', message: message);
