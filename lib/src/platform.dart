import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'layout_data.dart';
import 'layout_payload.dart';

abstract class IosWindowControlLayoutPlatform extends PlatformInterface {
  IosWindowControlLayoutPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosWindowControlLayoutPlatform _instance =
      MethodChannelIosWindowControlLayout();

  static IosWindowControlLayoutPlatform get instance => _instance;

  static set instance(IosWindowControlLayoutPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<IosWindowControlLayoutData> query() {
    throw UnimplementedError('query() has not been implemented.');
  }
}

/// Method-channel implementation of [IosWindowControlLayoutPlatform].
class MethodChannelIosWindowControlLayout
    extends IosWindowControlLayoutPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'ios_window_control_layout',
    StandardMethodCodec(),
  );

  @override
  Future<IosWindowControlLayoutData> query() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return IosWindowControlLayoutData.zero;
    }

    final value = await methodChannel.invokeMethod<Object?>('queryLayout');
    return LayoutPayload.decode(value).toLayoutData();
  }
}
