import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('queries a layout snapshot', (tester) async {
    final data = await IosWindowControlLayout.query();

    expect(data, isA<IosWindowControlLayoutData>());
    expect(data.isAvailable, isTrue);
    expect(data.baseMargins.start.isFinite, isTrue);
    expect(data.baseMargins.end.isFinite, isTrue);
    expect(data.horizontalAvoidance.start.isFinite, isTrue);
    expect(data.horizontalAvoidance.end.isFinite, isTrue);
    expect(data.baseSafeArea.start.isFinite, isTrue);
    expect(data.baseSafeArea.end.isFinite, isTrue);
    expect(data.horizontalSafeAreaAvoidance.start.isFinite, isTrue);
    expect(data.verticalSafeAreaAvoidance.bottom.isFinite, isTrue);
    expect(data.effectiveCornerRadii.bottomLeft.x.isFinite, isTrue);
  });
}
