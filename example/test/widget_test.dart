import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ios_window_control_layout');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => _layoutPayload());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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

  testWidgets('shows live iPad fullscreen and window-control status', (
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

Future<void> _pumpExample(WidgetTester tester) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<void> _enableRtl(WidgetTester tester) async {
  final rtlSwitch = find.byKey(const ValueKey('flutter-rtl-switch'));
  await tester.ensureVisible(rtlSwitch);
  await tester.tap(rtlSwitch);
  await tester.pumpAndSettle();
}

Map<String, Object> _layoutPayload({bool isFullScreen = false}) =>
    <String, Object>{
      'schemaVersion': 5,
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
