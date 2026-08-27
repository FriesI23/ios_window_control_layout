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

  test('decodes schema v2 margins and safe areas', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'queryLayout');
          return <String, Object>{
            'schemaVersion': 2,
            'isAvailable': true,
            'baseMargins': _insets(16, 12, 20, 8),
            'horizontalMargins': _insets(72, 12, 20, 8),
            'verticalMargins': _insets(16, 52, 20, 8),
            'baseSafeArea': _insets(4, 6, 8, 10),
            'horizontalSafeArea': _insets(24, 6, 8, 10),
            'verticalSafeArea': _insets(4, 36, 8, 10),
          };
        });

    final data = await platform.query();

    expect(data.isAvailable, isTrue);
    expect(
      data.horizontalAvoidance,
      const EdgeInsetsDirectional.only(start: 56),
    );
    expect(data.verticalAvoidance, const EdgeInsetsDirectional.only(top: 40));
    expect(
      data.horizontalSafeAreaAvoidance,
      const EdgeInsetsDirectional.only(start: 20),
    );
    expect(
      data.verticalSafeAreaAvoidance,
      const EdgeInsetsDirectional.only(top: 30),
    );
  });

  test('payload rejects an unsupported schema version', () {
    expect(
      () => LayoutPayload.decode(<String, Object>{'schemaVersion': 1}),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'invalid_data',
        ),
      ),
    );
  });

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
    test('rejects schema v2 payload missing $field', () {
      final payload = _validPayload()..remove(field);
      expect(() => LayoutPayload.decode(payload), _throwsInvalidData);
    });
  }

  for (final invalid in <Object>[const Object(), double.nan, double.infinity]) {
    test('rejects invalid numeric safe-area value $invalid', () {
      final payload = _validPayload();
      payload['horizontalSafeArea'] = <String, Object>{
        ..._insets(0, 0, 0, 0),
        'start': invalid,
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
  'schemaVersion': 2,
  'isAvailable': true,
  'baseMargins': _insets(0, 0, 0, 0),
  'horizontalMargins': _insets(0, 0, 0, 0),
  'verticalMargins': _insets(0, 0, 0, 0),
  'baseSafeArea': _insets(0, 0, 0, 0),
  'horizontalSafeArea': _insets(0, 0, 0, 0),
  'verticalSafeArea': _insets(0, 0, 0, 0),
};

Map<String, double> _insets(
  double start,
  double top,
  double end,
  double bottom,
) => <String, double>{'start': start, 'top': top, 'end': end, 'bottom': bottom};
