// Wire payloads mirrored by the native LayoutPayload.swift implementation.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'layout_data.dart';

/// Directional insets in the native wire payload.
///
/// Keep this structure synchronized with Swift's `DirectionalInsetsPayload`.
final class DirectionalInsetsPayload {
  const DirectionalInsetsPayload({
    required this.start,
    required this.top,
    required this.end,
    required this.bottom,
  });

  factory DirectionalInsetsPayload.decode(Object? value, String field) {
    final map = _expectMap(value, field);

    double number(String edge) {
      final value = map[edge];
      if (value is! num || !value.isFinite) {
        throw _invalidData('Expected $field.$edge to be a finite number.');
      }
      return value.toDouble();
    }

    return DirectionalInsetsPayload(
      start: number('start'),
      top: number('top'),
      end: number('end'),
      bottom: number('bottom'),
    );
  }

  final double start;
  final double top;
  final double end;
  final double bottom;

  EdgeInsetsDirectional toInsets() =>
      EdgeInsetsDirectional.fromSTEB(start, top, end, bottom);
}

/// Versioned wire payload transported by [StandardMethodCodec].
///
/// Keep this structure synchronized with Swift's `LayoutPayload`. Encoded
/// values must remain within the types supported by [StandardMessageCodec].
final class LayoutPayload {
  const LayoutPayload({
    required this.isAvailable,
    required this.baseMargins,
    required this.horizontalMargins,
    required this.verticalMargins,
    required this.baseSafeArea,
    required this.horizontalSafeArea,
    required this.verticalSafeArea,
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

    return LayoutPayload(
      isAvailable: isAvailable,
      baseMargins: DirectionalInsetsPayload.decode(
        map[_baseMarginsField],
        _baseMarginsField,
      ),
      horizontalMargins: DirectionalInsetsPayload.decode(
        map[_horizontalMarginsField],
        _horizontalMarginsField,
      ),
      verticalMargins: DirectionalInsetsPayload.decode(
        map[_verticalMarginsField],
        _verticalMarginsField,
      ),
      baseSafeArea: DirectionalInsetsPayload.decode(
        map[_baseSafeAreaField],
        _baseSafeAreaField,
      ),
      horizontalSafeArea: DirectionalInsetsPayload.decode(
        map[_horizontalSafeAreaField],
        _horizontalSafeAreaField,
      ),
      verticalSafeArea: DirectionalInsetsPayload.decode(
        map[_verticalSafeAreaField],
        _verticalSafeAreaField,
      ),
    );
  }

  static const schemaVersion = 2;
  static const _schemaVersionField = 'schemaVersion';
  static const _isAvailableField = 'isAvailable';
  static const _baseMarginsField = 'baseMargins';
  static const _horizontalMarginsField = 'horizontalMargins';
  static const _verticalMarginsField = 'verticalMargins';
  static const _baseSafeAreaField = 'baseSafeArea';
  static const _horizontalSafeAreaField = 'horizontalSafeArea';
  static const _verticalSafeAreaField = 'verticalSafeArea';

  final bool isAvailable;
  final DirectionalInsetsPayload baseMargins;
  final DirectionalInsetsPayload horizontalMargins;
  final DirectionalInsetsPayload verticalMargins;
  final DirectionalInsetsPayload baseSafeArea;
  final DirectionalInsetsPayload horizontalSafeArea;
  final DirectionalInsetsPayload verticalSafeArea;

  IosWindowControlLayoutData toLayoutData() => IosWindowControlLayoutData(
    isAvailable: isAvailable,
    baseMargins: baseMargins.toInsets(),
    horizontalMargins: horizontalMargins.toInsets(),
    verticalMargins: verticalMargins.toInsets(),
    baseSafeArea: baseSafeArea.toInsets(),
    horizontalSafeArea: horizontalSafeArea.toInsets(),
    verticalSafeArea: verticalSafeArea.toInsets(),
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
