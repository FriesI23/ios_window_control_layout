import 'package:flutter/foundation.dart';
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
    expect(find.text('Horizontal avoidance preview'), findsOneWidget);
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

Map<String, Object> _layoutPayload() => <String, Object>{
  'schemaVersion': 1,
  'isAvailable': true,
  'baseMargins': _insets(0, 0, 0, 0),
  'horizontalMargins': _insets(80, 0, 20, 0),
  'verticalMargins': _insets(0, 0, 0, 0),
};

Map<String, double> _insets(
  double start,
  double top,
  double end,
  double bottom,
) => <String, double>{'start': start, 'top': top, 'end': end, 'bottom': bottom};
