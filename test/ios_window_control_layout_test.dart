import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
import 'package:ios_window_control_layout/ios_window_control_layout_platform_interface.dart';
import 'package:ios_window_control_layout/ios_window_control_layout_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIosWindowControlLayoutPlatform
    with MockPlatformInterfaceMixin
    implements IosWindowControlLayoutPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IosWindowControlLayoutPlatform initialPlatform = IosWindowControlLayoutPlatform.instance;

  test('$MethodChannelIosWindowControlLayout is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosWindowControlLayout>());
  });

  test('getPlatformVersion', () async {
    IosWindowControlLayout iosWindowControlLayoutPlugin = IosWindowControlLayout();
    MockIosWindowControlLayoutPlatform fakePlatform = MockIosWindowControlLayoutPlatform();
    IosWindowControlLayoutPlatform.instance = fakePlatform;

    expect(await iosWindowControlLayoutPlugin.getPlatformVersion(), '42');
  });
}
