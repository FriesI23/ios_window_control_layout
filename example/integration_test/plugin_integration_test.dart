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
    expect(data.baseMargins.start.isFinite, isTrue);
    expect(data.baseMargins.end.isFinite, isTrue);
    expect(data.horizontalAvoidance.start.isFinite, isTrue);
    expect(data.horizontalAvoidance.end.isFinite, isTrue);
    expect(data.baseSafeArea.start.isFinite, isTrue);
    expect(data.baseSafeArea.end.isFinite, isTrue);
    expect(data.horizontalSafeAreaAvoidance.start.isFinite, isTrue);
    expect(data.verticalSafeAreaAvoidance.bottom.isFinite, isTrue);
    expect(data.effectiveCornerRadii.bottomLeft.x.isFinite, isTrue);

    if (!data.isAvailable) {
      expect(data.baseMargins, EdgeInsetsDirectional.zero);
      expect(data.horizontalMargins, EdgeInsetsDirectional.zero);
      expect(data.verticalMargins, EdgeInsetsDirectional.zero);
      expect(data.baseSafeArea, EdgeInsetsDirectional.zero);
      expect(data.horizontalSafeArea, EdgeInsetsDirectional.zero);
      expect(data.verticalSafeArea, EdgeInsetsDirectional.zero);
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
