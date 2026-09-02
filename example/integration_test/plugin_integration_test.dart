import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('queries a layout snapshot', (tester) async {
    final data = await IosWindowControlLayout.query();

    expect(data, isA<IosWindowControlLayoutData>());
    _expectConfiguredState(data);
    expect(data.baseMargins.left.isFinite, isTrue);
    expect(data.baseMargins.right.isFinite, isTrue);
    expect(data.horizontalAvoidance.left.isFinite, isTrue);
    expect(data.horizontalAvoidance.right.isFinite, isTrue);
    expect(data.baseSafeArea.left.isFinite, isTrue);
    expect(data.baseSafeArea.right.isFinite, isTrue);
    expect(data.horizontalSafeAreaAvoidance.left.isFinite, isTrue);
    expect(data.verticalSafeAreaAvoidance.bottom.isFinite, isTrue);
    expect(data.effectiveCornerRadii.bottomLeft.x.isFinite, isTrue);

    if (!data.isAvailable) {
      expect(data.baseMargins, EdgeInsets.zero);
      expect(data.horizontalMargins, EdgeInsets.zero);
      expect(data.verticalMargins, EdgeInsets.zero);
      expect(data.baseSafeArea, EdgeInsets.zero);
      expect(data.horizontalSafeArea, EdgeInsets.zero);
      expect(data.verticalSafeArea, EdgeInsets.zero);
      expect(data.effectiveCornerRadii, BorderRadius.zero);
    }
  });
}

void _expectConfiguredState(IosWindowControlLayoutData data) {
  const expectedIsPad = String.fromEnvironment('EXPECTED_IS_PAD');
  if (expectedIsPad.isNotEmpty) {
    expect(data.isPad, expectedIsPad == 'true');
  }

  const expectedIsAvailable = String.fromEnvironment('EXPECTED_IS_AVAILABLE');
  if (expectedIsAvailable.isNotEmpty) {
    expect(data.isAvailable, expectedIsAvailable == 'true');
  }
}
