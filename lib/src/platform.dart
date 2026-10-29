import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'layout_data.dart';
import 'layout_payload.dart';

/// Platform contract for querying layout and observing system occlusion changes.
///
/// Extend this class to provide another backend. Test fakes may implement it
/// with [MockPlatformInterfaceMixin].
abstract class IosWindowControlLayoutPlatform extends PlatformInterface {
  /// Creates the default platform-channel implementation.
  factory IosWindowControlLayoutPlatform() =
      _MethodChannelIosWindowControlLayout;

  /// Constructor for platform implementations that extend this class.
  IosWindowControlLayoutPlatform.base() : super(token: _token);

  static final Object _token = Object();
  static IosWindowControlLayoutPlatform _instance =
      IosWindowControlLayoutPlatform();

  /// The shared implementation used by the layout widget and its query API.
  static IosWindowControlLayoutPlatform get instance => _instance;

  /// Replaces the shared implementation after validating its platform token.
  static set instance(IosWindowControlLayoutPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Signals that consumers must discard their previous occlusion geometry.
  ///
  /// Events carry no geometry; call [query] again after each invalidation.
  /// Implementations without change notifications return an empty stream.
  Stream<void> get occlusionChanges => const Stream<void>.empty();

  /// Queries a snapshot in the current Flutter view's logical coordinates.
  ///
  /// The default implementation returns [IosWindowControlLayoutData.zero] on
  /// unsupported platforms and surfaces native failures as [PlatformException]s.
  Future<IosWindowControlLayoutData> query();
}

final class _MethodChannelIosWindowControlLayout
    extends IosWindowControlLayoutPlatform {
  static const _channelName = 'ios_window_control_layout';
  static const _occlusionChannelName =
      'ios_window_control_layout/occlusion_changes';

  final _methodChannel = const MethodChannel(
    _channelName,
    StandardMethodCodec(),
  );
  final _occlusionEventChannel = const EventChannel(_occlusionChannelName);

  Stream<void>? _occlusionChanges;

  _MethodChannelIosWindowControlLayout() : super.base();

  @override
  Stream<void> get occlusionChanges {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const Stream<void>.empty();
    }
    return _occlusionChanges ??= _occlusionEventChannel
        .receiveBroadcastStream()
        .map<void>((_) {});
  }

  @override
  Future<IosWindowControlLayoutData> query() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return IosWindowControlLayoutData.zero;
    }

    final value = await _methodChannel.invokeMethod<Object?>('queryLayout');
    return LayoutPayload.decode(value).toLayoutData();
  }
}
