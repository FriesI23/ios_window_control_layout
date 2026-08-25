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

  test('parses directional layout margins', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'queryLayout');
          return <String, Object>{
            'schemaVersion': 1,
            'isAvailable': true,
            'baseMargins': _insets(16, 12, 20, 8),
            'horizontalMargins': _insets(72, 12, 20, 8),
            'verticalMargins': _insets(16, 52, 20, 8),
          };
        });

    final data = await platform.query();

    expect(data.isAvailable, isTrue);
    expect(
      data.horizontalAvoidance,
      const EdgeInsetsDirectional.only(start: 56),
    );
    expect(data.verticalAvoidance, const EdgeInsetsDirectional.only(top: 40));
  });

  test('payload rejects an unsupported schema version', () {
    expect(
      () => LayoutPayload.decode(<String, Object>{'schemaVersion': 2}),
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

  test('rejects malformed native data with a stable error code', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return <String, Object>{
            'schemaVersion': 1,
            'isAvailable': true,
            'baseMargins': _insets(0, 0, 0, 0),
            'horizontalMargins': <String, Object>{'start': double.nan},
            'verticalMargins': _insets(0, 0, 0, 0),
          };
        });

    await expectLater(
      platform.query(),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'invalid_data',
        ),
      ),
    );
  });
}

Map<String, double> _insets(
  double start,
  double top,
  double end,
  double bottom,
) => <String, double>{'start': start, 'top': top, 'end': end, 'bottom': bottom};
