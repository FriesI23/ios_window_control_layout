
import 'ios_window_control_layout_platform_interface.dart';

class IosWindowControlLayout {
  Future<String?> getPlatformVersion() {
    return IosWindowControlLayoutPlatform.instance.getPlatformVersion();
  }
}
