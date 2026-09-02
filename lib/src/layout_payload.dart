// Wire payloads mirrored by the native LayoutPayload.swift implementation.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'layout_data.dart';

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
      effectiveCornerRadii: CornerRadiiPayload.decode(
        map[_effectiveCornerRadiiField],
        _effectiveCornerRadiiField,
      ),
    );
  }

  static const schemaVersion = 5;
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
