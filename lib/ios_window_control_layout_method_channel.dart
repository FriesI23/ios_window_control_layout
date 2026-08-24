import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_window_control_layout_platform_interface.dart';

/// An implementation of [IosWindowControlLayoutPlatform] that uses method channels.
class MethodChannelIosWindowControlLayout extends IosWindowControlLayoutPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_window_control_layout');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
