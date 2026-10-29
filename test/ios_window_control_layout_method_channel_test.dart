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
  const eventChannel = MethodChannel(
    'ios_window_control_layout/occlusion_changes',
  );
  final platform = IosWindowControlLayoutPlatform();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, null);
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('decodes schema v6 window state and physical geometry', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'queryLayout');
          return <String, Object>{
            'schemaVersion': 6,
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
            'occlusionGeometry': _occlusionPayload(),
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

  test('distinguishes unavailable and valid empty occlusions', () {
    final payload = _validPayload();
    expect(
      LayoutPayload.decode(payload).toLayoutData().occlusionGeometry,
      isNull,
    );
    payload['occlusionGeometry'] = _occlusionPayload(regions: []);
    final geometry = LayoutPayload.decode(
      payload,
    ).toLayoutData().occlusionGeometry!;
    expect(geometry.viewBounds, const Rect.fromLTWH(0, 0, 800, 600));
    expect(geometry.activeOcclusionRegions, isEmpty);
    expect(geometry.hasVerticalSystemBar, isTrue);
  });

  test('keeps physical negative and out-of-view occlusion coordinates', () {
    final payload = _validPayload()
      ..['occlusionGeometry'] = _occlusionPayload(
        regions: [_rect(-10, -20, 100, 900)],
      );
    final geometry = LayoutPayload.decode(
      payload,
    ).toLayoutData().occlusionGeometry!;
    expect(geometry.activeOcclusionRegions, [
      const Rect.fromLTWH(-10, -20, 100, 900),
    ]);
    expect(
      () => geometry.activeOcclusionRegions.clear(),
      throwsUnsupportedError,
    );
  });

  test('decodes optional public bar layout geometry without requiring it', () {
    final wire = _occlusionPayload();
    final payload = _validPayload()..['occlusionGeometry'] = wire;
    expect(
      LayoutPayload.decode(
        payload,
      ).toLayoutData().occlusionGeometry!.verticalBarLayoutFrame,
      isNull,
    );
    wire['verticalBarLayoutFrame'] = _rect(730, 124, 44, 442);
    final geometry = LayoutPayload.decode(
      payload,
    ).toLayoutData().occlusionGeometry!;
    expect(
      geometry.verticalBarLayoutFrame,
      const Rect.fromLTWH(730, 124, 44, 442),
    );
    expect(geometry.activeOcclusionRegions, isNotEmpty);
  });

  test(
    'invalid optional bar layout data does not discard valid occlusions',
    () {
      for (final frame in <Object?>[
        null,
        'invalid',
        [],
        _rect(0, 0, 0, 40),
        _rect(0, 0, 40, -1),
        _rect(double.nan, 0, 44, 40),
        _rect(0, 0, double.infinity, 40),
      ]) {
        final wire = <String, Object?>{
          ..._occlusionPayload(),
          'verticalBarLayoutFrame': frame,
        };
        final geometry = LayoutPayload.decode(
          _validPayload()..['occlusionGeometry'] = wire,
        ).toLayoutData().occlusionGeometry!;
        expect(geometry.verticalBarLayoutFrame, isNull);
        expect(geometry.hasVerticalSystemBar, isTrue);
        expect(geometry.activeOcclusionRegions, isNotEmpty);
      }
    },
  );

  test('schema v6 requires the nullable occlusion field', () {
    expect(
      () => LayoutPayload.decode(_validPayload()..remove('occlusionGeometry')),
      _throwsInvalidData,
    );
  });

  for (final field in [
    'viewBounds',
    'activeOcclusionRegions',
    'hasVerticalSystemBar',
  ]) {
    test('rejects missing occlusion $field', () {
      final geometry = _occlusionPayload()..remove(field);
      expect(
        () => LayoutPayload.decode(
          _validPayload()..['occlusionGeometry'] = geometry,
        ),
        _throwsInvalidData,
      );
    });
  }

  for (final invalid in <Object>['invalid', [], true]) {
    test('rejects malformed occlusion geometry $invalid', () {
      expect(
        () => LayoutPayload.decode(
          _validPayload()..['occlusionGeometry'] = invalid,
        ),
        _throwsInvalidData,
      );
    });
  }

  for (final field in ['x', 'y', 'width', 'height']) {
    for (final invalid in <Object>[double.nan, double.infinity, 'invalid']) {
      test('rejects non-finite or non-numeric occlusion $field=$invalid', () {
        final rect = <String, Object>{..._rect(0, 0, 10, 10), field: invalid};
        final payload = _validPayload()
          ..['occlusionGeometry'] = _occlusionPayload(regions: [rect]);
        expect(() => LayoutPayload.decode(payload), _throwsInvalidData);
      });
    }
  }

  test(
    'rejects invalid dimensions, bounds overflow, and malformed list/flag',
    () {
      final geometries = <Map<String, Object>>[
        {..._occlusionPayload(), 'viewBounds': _rect(0, 0, 0, 10)},
        {..._occlusionPayload(), 'viewBounds': _rect(0, 0, 10, -1)},
        _occlusionPayload(regions: [_rect(0, 0, -1, 10)]),
        _occlusionPayload(
          regions: [_rect(double.maxFinite, 0, double.maxFinite, 10)],
        ),
        {..._occlusionPayload(), 'activeOcclusionRegions': 'invalid'},
        {
          ..._occlusionPayload(),
          'activeOcclusionRegions': [null],
        },
        {..._occlusionPayload(), 'hasVerticalSystemBar': 'true'},
      ];
      for (final geometry in geometries) {
        expect(
          () => LayoutPayload.decode(
            _validPayload()..['occlusionGeometry'] = geometry,
          ),
          _throwsInvalidData,
        );
      }
    },
  );

  test(
    'native event channel exposes invalidations and cancels its listener',
    () async {
      final calls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(eventChannel, (call) async {
        calls.add(call.method);
        return null;
      });
      final eventPlatform = IosWindowControlLayoutPlatform();
      var events = 0;
      final subscription = eventPlatform.occlusionChanges.listen(
        (_) => events++,
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['listen']);
      await messenger.handlePlatformMessage(
        eventChannel.name,
        const StandardMethodCodec().encodeSuccessEnvelope(1),
        (_) {},
      );
      expect(events, 1);
      await subscription.cancel();
      expect(calls, ['listen', 'cancel']);
    },
  );

  test('payload rejects the previous schema version', () {
    expect(
      () => LayoutPayload.decode(<String, Object>{'schemaVersion': 5}),
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
    test('rejects schema v6 payload missing $field', () {
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

Map<String, Object?> _validPayload() => <String, Object?>{
  'schemaVersion': 6,
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
  'occlusionGeometry': null,
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

Map<String, Object> _occlusionPayload({List<Object>? regions}) => {
  'viewBounds': _rect(0, 0, 800, 600),
  'activeOcclusionRegions': regions ?? [_rect(720, 0, 80, 100)],
  'hasVerticalSystemBar': true,
};

Map<String, double> _rect(double x, double y, double width, double height) => {
  'x': x,
  'y': y,
  'width': width,
  'height': height,
};
