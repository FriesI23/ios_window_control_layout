import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ios_window_control_layout');
  const eventChannel = MethodChannel(
    'ios_window_control_layout/occlusion_changes',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => _layoutPayload());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('occlusion diagnostics are optional and do not move controls', (
    tester,
  ) async {
    await _pumpExample(tester);
    expect(
      find.byKey(const ValueKey('occlusion-diagnostics-overlay')),
      findsNothing,
    );
    final before = tester.getRect(
      find.byKey(const ValueKey('cupertino-leading')),
    );
    final toggle = find.byKey(const ValueKey('toggle-occlusion-diagnostics'));
    await tester.tap(find.byKey(const ValueKey('app-bar-style-menu')));
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final overlay = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('occlusion-diagnostics-overlay')),
    );
    expect(overlay.ignoring, isTrue);
    expect(find.textContaining('hasVerticalSystemBar: true'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('cupertino-leading'))),
      before,
    );
    await tester.tap(find.byKey(const ValueKey('app-bar-style-menu')));
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('occlusion-diagnostics-overlay')),
      findsNothing,
    );
  });

  _testIosWidgets(
    'recommended bar remains physical in RTL and can be unavailable',
    (tester) async {
      var hasBar = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => _layoutPayload(
              verticalBarLayoutFrame: hasBar
                  ? const Rect.fromLTWH(736, 100, 44, 472)
                  : null,
            ),
          );
      await _pumpExample(tester);
      await _showDiagnostics(tester);
      await _enableRtl(tester);

      expect(find.textContaining('Bar center x: 758.0'), findsOneWidget);
      final status = tester.widget<Text>(
        find.byKey(const ValueKey('occlusion-diagnostics-status')),
      );
      expect(status.textDirection, TextDirection.ltr);

      hasBar = false;
      await tester.tap(find.byKey(const ValueKey('cupertino-trailing')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Recommended bar: unavailable'),
        findsOneWidget,
      );
      expect(find.textContaining('Bar center x:'), findsNothing);
      expect(find.textContaining('Active regions: 1'), findsOneWidget);
    },
  );

  _testIosWidgets(
    'diagnostics distinguish valid empty regions from unavailable',
    (tester) async {
      var available = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => _layoutPayload(
              occlusionAvailable: available,
              emptyOcclusions: true,
            ),
          );
      await _pumpExample(tester);
      await _showDiagnostics(tester);
      expect(find.textContaining('Active regions: 0'), findsOneWidget);
      expect(find.text('Occlusion geometry unavailable'), findsNothing);
      expect(find.textContaining('Bar center x: 758.0'), findsOneWidget);

      available = false;
      await tester.tap(find.byKey(const ValueKey('cupertino-trailing')));
      await tester.pumpAndSettle();
      expect(find.text('Occlusion geometry unavailable'), findsOneWidget);
      expect(find.textContaining('Bar center x:'), findsNothing);
    },
  );

  _testIosWidgets('native invalidation clears the old bar before its update', (
    tester,
  ) async {
    final pending = Completer<Map<String, Object?>>();
    var queries = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) =>
              ++queries == 1 ? Future.value(_layoutPayload()) : pending.future,
        );
    await _pumpExample(tester);
    await _showDiagnostics(tester);
    expect(find.textContaining('Bar center x: 758.0'), findsOneWidget);

    await _emitOcclusionEvent(tester);
    await tester.pump();
    expect(find.text('Occlusion geometry unavailable'), findsOneWidget);
    expect(find.textContaining('Bar center x:'), findsNothing);

    pending.complete(
      _layoutPayload(
        verticalBarLayoutFrame: const Rect.fromLTWH(10, 120, 44, 400),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Bar center x: 32.0'), findsOneWidget);
    expect(find.textContaining('Bar center x: 758.0'), findsNothing);
    expect(find.text('Occlusion geometry unavailable'), findsNothing);
  });

  testWidgets('switches between Material and Cupertino app bars', (
    tester,
  ) async {
    await _pumpExample(tester);

    expect(find.byKey(const ValueKey('material-leading')), findsNothing);
    expect(find.byKey(const ValueKey('cupertino-leading')), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('apply-window-control-layout-switch')),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('app-bar-style-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-material-app-bar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('material-leading')), findsOneWidget);
    expect(find.byKey(const ValueKey('cupertino-leading')), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Horizontal avoidance preview'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('flutter-safe-area-color')),
      findsOneWidget,
    );
    final floatingControl = tester.widget<Opacity>(
      find.byKey(const ValueKey('uikit-floating-control')),
    );
    expect(floatingControl.opacity, 0.85);
  });

  testWidgets('keeps the Material title centered with baseline edge padding', (
    tester,
  ) async {
    await _pumpExample(tester);

    await tester.tap(find.byKey(const ValueKey('app-bar-style-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-material-app-bar')));
    await tester.pumpAndSettle();

    final appBar = tester.getRect(find.byType(AppBar));
    final title = tester.getRect(find.text('Material'));
    final leading = tester.getRect(
      find.byKey(const ValueKey('material-leading')),
    );
    final trailing = tester.getRect(
      find.byKey(const ValueKey('material-trailing')),
    );

    expect(title.center.dx, closeTo(appBar.center.dx, 0.01));
    expect(leading.left, greaterThanOrEqualTo(96));
    expect(trailing.right, lessThanOrEqualTo(appBar.right - 36));

    await tester.tap(
      find.byKey(const ValueKey('apply-window-control-layout-switch')),
    );
    await tester.pumpAndSettle();

    final untreatedLeading = tester.getRect(
      find.byKey(const ValueKey('material-leading')),
    );
    final untreatedTrailing = tester.getRect(
      find.byKey(const ValueKey('material-trailing')),
    );

    expect(untreatedLeading.left, closeTo(16, 0.01));
    expect(untreatedTrailing.right, closeTo(appBar.right - 16, 0.01));
  });

  testWidgets('bottom controls ignore top window-control safe-area insets', (
    tester,
  ) async {
    await _pumpExample(tester);

    final boundaryPadding = tester.widget<Padding>(
      find.byKey(const ValueKey('bottom-boundary-padding')),
    );
    expect(boundaryPadding.padding, const EdgeInsets.only(bottom: 28));
  });

  testWidgets('Material keeps physical left avoidance in Flutter RTL', (
    tester,
  ) async {
    await _pumpExample(tester);
    await tester.tap(find.byKey(const ValueKey('app-bar-style-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-material-app-bar')));
    await tester.pumpAndSettle();
    await _enableRtl(tester);

    final appBar = tester.getRect(find.byType(AppBar));
    final leading = tester.getRect(
      find.byKey(const ValueKey('material-leading')),
    );
    final trailing = tester.getRect(
      find.byKey(const ValueKey('material-trailing')),
    );

    expect(leading.right, lessThanOrEqualTo(appBar.right - 36));
    expect(trailing.left, greaterThanOrEqualTo(appBar.left + 96));
  });

  testWidgets('Cupertino keeps physical left avoidance in Flutter RTL', (
    tester,
  ) async {
    await _pumpExample(tester);
    await _enableRtl(tester);

    final navigationBar = tester.getRect(find.byType(CupertinoNavigationBar));
    final leading = tester.getRect(
      find.byKey(const ValueKey('cupertino-leading')),
    );
    final trailing = tester.getRect(
      find.byKey(const ValueKey('cupertino-trailing')),
    );

    expect(leading.right, lessThanOrEqualTo(navigationBar.right - 36));
    expect(trailing.left, greaterThanOrEqualTo(navigationBar.left + 96));
  });

  _testIosWidgets('shows live iPad fullscreen and window-control status', (
    tester,
  ) async {
    var isFullScreen = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => _layoutPayload(isFullScreen: isFullScreen),
        );

    await _pumpExample(tester);

    expect(find.text('Interface idiom: iPad'), findsOneWidget);
    expect(find.text('Window mode: windowed'), findsOneWidget);
    expect(find.text('iPad window-control avoidance: present'), findsOneWidget);

    isFullScreen = true;
    tester.binding.handleMetricsChanged();
    await tester.pump();

    expect(find.text('Window mode: fullscreen'), findsOneWidget);
    expect(find.text('iPad window-control avoidance: absent'), findsOneWidget);
  });
}

void _testIosWidgets(String description, WidgetTesterCallback test) {
  testWidgets(
    description,
    test,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

Future<void> _pumpExample(WidgetTester tester) async {
  final previousPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();
  } finally {
    debugDefaultTargetPlatformOverride = previousPlatform;
  }
}

Future<void> _showDiagnostics(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('app-bar-style-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('toggle-occlusion-diagnostics')));
  await tester.pumpAndSettle();
}

Future<void> _emitOcclusionEvent(WidgetTester tester) {
  final delivered = Completer<void>();
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'ios_window_control_layout/occlusion_changes',
    const StandardMethodCodec().encodeSuccessEnvelope(null),
    (_) => delivered.complete(),
  );
  return delivered.future;
}

Future<void> _enableRtl(WidgetTester tester) async {
  final rtlSwitch = find.byKey(const ValueKey('flutter-rtl-switch'));
  await tester.ensureVisible(rtlSwitch);
  await tester.tap(rtlSwitch);
  await tester.pumpAndSettle();
}

Map<String, Object?> _layoutPayload({
  bool isFullScreen = false,
  bool occlusionAvailable = true,
  bool emptyOcclusions = false,
  Rect? verticalBarLayoutFrame = const Rect.fromLTWH(736, 100, 44, 472),
}) => <String, Object?>{
  'schemaVersion': 6,
  'occlusionGeometry': !occlusionAvailable
      ? null
      : <String, Object>{
          'viewBounds': <String, double>{
            'x': 0,
            'y': 0,
            'width': 800,
            'height': 600,
          },
          'activeOcclusionRegions': [
            if (!emptyOcclusions)
              <String, double>{'x': 720, 'y': 0, 'width': 80, 'height': 100},
          ],
          'hasVerticalSystemBar': true,
          if (verticalBarLayoutFrame != null)
            'verticalBarLayoutFrame': <String, double>{
              'x': verticalBarLayoutFrame.left,
              'y': verticalBarLayoutFrame.top,
              'width': verticalBarLayoutFrame.width,
              'height': verticalBarLayoutFrame.height,
            },
        },
  'isAvailable': true,
  'isPad': true,
  'isFullScreen': isFullScreen,
  'baseMargins': _insets(0, 0, 0, 0),
  'horizontalMargins': _insets(80, 0, 20, 0),
  'verticalMargins': _insets(0, 0, 0, 0),
  'baseSafeArea': _insets(0, 0, 0, 12),
  'horizontalSafeArea': _insets(96, 0, 48, 28),
  'verticalSafeArea': _insets(0, 0, 0, 28),
  'effectiveCornerRadii': <String, double>{
    'topLeft': 62,
    'topRight': 62,
    'bottomLeft': 26,
    'bottomRight': 26,
  },
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
