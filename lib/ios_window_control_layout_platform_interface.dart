import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_window_control_layout_method_channel.dart';

abstract class IosWindowControlLayoutPlatform extends PlatformInterface {
  /// Constructs a IosWindowControlLayoutPlatform.
  IosWindowControlLayoutPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosWindowControlLayoutPlatform _instance = MethodChannelIosWindowControlLayout();

  /// The default instance of [IosWindowControlLayoutPlatform] to use.
  ///
  /// Defaults to [MethodChannelIosWindowControlLayout].
  static IosWindowControlLayoutPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosWindowControlLayoutPlatform] when
  /// they register themselves.
  static set instance(IosWindowControlLayoutPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
