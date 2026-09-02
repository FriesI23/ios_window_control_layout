import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
import 'package:ios_window_control_layout/src/layout_payload.dart';
import 'package:ios_window_control_layout/src/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ios_window_control_layout');
  final platform = MethodChannelIosWindowControlLayout();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('decodes schema v5 window state and physical geometry', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'queryLayout');
          return <String, Object>{
            'schemaVersion': 5,
            'isAvailable': true,
            'isPad': true,
            'isFullScreen': false,
            'baseMargins': _insets(16, 12, 20, 8),
            'horizontalMargins': _insets(72, 12, 20, 8),
            'verticalMargins': _insets(16, 52, 20, 8),
            'baseSafeArea': _insets(4, 6, 8, 10),
            'horizontalSafeArea': _insets(24, 6, 8, 10),
            'verticalSafeArea': _insets(4, 36, 8, 10),
            'effectiveCornerRadii': _radii(52, 54, 60, 62),
          };
        });

    final data = await platform.query();

    expect(data.isAvailable, isTrue);
    expect(data.isPad, isTrue);
    expect(data.isFullScreen, isFalse);
    expect(data.hasWindowControlAvoidance, isTrue);
    expect(data.horizontalAvoidance, const EdgeInsets.only(left: 56));
    expect(data.verticalAvoidance, const EdgeInsets.only(top: 40));
    expect(data.horizontalSafeAreaAvoidance, const EdgeInsets.only(left: 20));
    expect(data.verticalSafeAreaAvoidance, const EdgeInsets.only(top: 30));
    expect(
      data.effectiveCornerRadii,
      const BorderRadius.only(
        topLeft: Radius.circular(52),
        topRight: Radius.circular(54),
        bottomLeft: Radius.circular(60),
        bottomRight: Radius.circular(62),
      ),
    );
  });

  test('payload rejects the previous schema version', () {
    expect(
      () => LayoutPayload.decode(<String, Object>{'schemaVersion': 4}),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'invalid_data',
        ),
      ),
    );
  });

  for (final edge in const ['left', 'top', 'right', 'bottom']) {
    test('rejects a physical inset missing $edge', () {
      final payload = _validPayload();
      final insets = Map<String, Object>.from(
        payload['baseMargins']! as Map<String, double>,
      )..remove(edge);
      payload['baseMargins'] = insets;

      expect(() => LayoutPayload.decode(payload), _throwsInvalidData);
    });
  }

  test('returns zero without invoking a channel outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var invoked = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          invoked = true;
          return null;
        });

    expect(await platform.query(), IosWindowControlLayoutData.zero);
    expect(invoked, isFalse);
  });

  for (final field in const [
    'baseSafeArea',
    'horizontalSafeArea',
    'verticalSafeArea',
  ]) {
    test('rejects schema v5 payload missing $field', () {
      final payload = _validPayload()..remove(field);
      expect(() => LayoutPayload.decode(payload), _throwsInvalidData);
    });
  }

  test('rejects a missing corner-radii payload', () {
    final payload = _validPayload()..remove('effectiveCornerRadii');
    expect(() => LayoutPayload.decode(payload), _throwsInvalidData);
  });

  for (final field in const ['isAvailable', 'isPad', 'isFullScreen']) {
    test('rejects a missing or malformed $field', () {
      final missing = _validPayload()..remove(field);
      expect(() => LayoutPayload.decode(missing), _throwsInvalidData);

      final malformed = _validPayload()..[field] = 'false';
      expect(() => LayoutPayload.decode(malformed), _throwsInvalidData);
    });
  }

  for (final invalid in <Object>[
    -1,
    const Object(),
    double.nan,
    double.infinity,
  ]) {
    test('rejects invalid corner radius $invalid', () {
      final payload = _validPayload();
      payload['effectiveCornerRadii'] = <String, Object>{
        ..._radii(0, 0, 0, 0),
        'bottomLeft': invalid,
      };
      expect(() => LayoutPayload.decode(payload), _throwsInvalidData);
    });
  }

  for (final invalid in <Object>[const Object(), double.nan, double.infinity]) {
    test('rejects invalid numeric safe-area value $invalid', () {
      final payload = _validPayload();
      payload['horizontalSafeArea'] = <String, Object>{
        ..._insets(0, 0, 0, 0),
        'left': invalid,
      };
      expect(() => LayoutPayload.decode(payload), _throwsInvalidData);
    });
  }
}

final _throwsInvalidData = throwsA(
  isA<PlatformException>().having(
    (error) => error.code,
    'code',
    'invalid_data',
  ),
);

Map<String, Object> _validPayload() => <String, Object>{
  'schemaVersion': 5,
  'isAvailable': true,
  'isPad': true,
  'isFullScreen': false,
  'baseMargins': _insets(0, 0, 0, 0),
  'horizontalMargins': _insets(0, 0, 0, 0),
  'verticalMargins': _insets(0, 0, 0, 0),
  'baseSafeArea': _insets(0, 0, 0, 0),
  'horizontalSafeArea': _insets(0, 0, 0, 0),
  'verticalSafeArea': _insets(0, 0, 0, 0),
  'effectiveCornerRadii': _radii(0, 0, 0, 0),
};

Map<String, double> _insets(
  double left,
  double top,
  double right,
  double bottom,
) => <String, double>{
  'left': left,
  'top': top,
  'right': right,
  'bottom': bottom,
};

Map<String, double> _radii(
  double topLeft,
  double topRight,
  double bottomLeft,
  double bottomRight,
) => <String, double>{
  'topLeft': topLeft,
  'topRight': topRight,
  'bottomLeft': bottomLeft,
  'bottomRight': bottomRight,
};
