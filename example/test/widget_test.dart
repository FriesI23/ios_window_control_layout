import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout_example/main.dart';

void main() {
  testWidgets('switches between Material and Cupertino app bars', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.byKey(const ValueKey('material-leading')), findsOneWidget);
    expect(find.byKey(const ValueKey('cupertino-leading')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('app-bar-style-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-cupertino-app-bar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('material-leading')), findsNothing);
    expect(find.byKey(const ValueKey('cupertino-leading')), findsOneWidget);
    expect(find.text('Horizontal avoidance preview'), findsOneWidget);
  });
}
