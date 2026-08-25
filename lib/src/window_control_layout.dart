import 'dart:async';

import 'package:flutter/widgets.dart';

import 'layout_data.dart';
import 'platform.dart';

/// Provides UIKit's corner-adapted layout margins to its descendants.
///
/// The layout refreshes after its first frame, when Flutter reports new window
/// metrics, and when the application resumes. Call [refresh] when an
/// application-specific event can change the native window chrome without a
/// corresponding Flutter metrics update.
class IosWindowControlLayout extends StatefulWidget {
  /// Creates a widget that owns and refreshes its layout snapshot.
  const IosWindowControlLayout({super.key, required this.child});

  /// The subtree that can read the layout snapshot.
  final Widget child;

  /// Returns the current snapshot and rebuilds when it changes.
  static IosWindowControlLayoutData of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_InheritedWindowControlLayout>();
    assert(inherited != null, _missingLayoutMessage);
    return inherited!.data;
  }

  /// Returns the current snapshot, or null when no layout is present.
  ///
  /// The calling widget rebuilds when the snapshot changes.
  static IosWindowControlLayoutData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedWindowControlLayout>()
      ?.data;

  /// Returns the current snapshot without establishing a dependency.
  static IosWindowControlLayoutData read(BuildContext context) {
    final inherited = context
        .getInheritedWidgetOfExactType<_InheritedWindowControlLayout>();
    assert(inherited != null, _missingLayoutMessage);
    return inherited!.data;
  }

  /// Returns the current snapshot without establishing a dependency, or null.
  static IosWindowControlLayoutData? maybeRead(BuildContext context) => context
      .getInheritedWidgetOfExactType<_InheritedWindowControlLayout>()
      ?.data;

  /// Requests a new native query from the nearest layout widget.
  static Future<void> refresh(BuildContext context) {
    final inherited = context
        .getInheritedWidgetOfExactType<_InheritedWindowControlLayout>();
    assert(inherited != null, _missingLayoutMessage);
    return inherited!.refresh();
  }

  /// Queries the layout margins for the current Flutter view.
  ///
  /// Unsupported platforms and iOS versions before iOS 26 return
  /// [IosWindowControlLayoutData.zero]. Native integration failures are
  /// surfaced as platform exceptions.
  static Future<IosWindowControlLayoutData> query() =>
      IosWindowControlLayoutPlatform.instance.query();

  static const _missingLayoutMessage =
      'No IosWindowControlLayout found in this context.';

  @override
  State<IosWindowControlLayout> createState() => _IosWindowControlLayoutState();
}

class _IosWindowControlLayoutState extends State<IosWindowControlLayout>
    with WidgetsBindingObserver {
  IosWindowControlLayoutData _data = IosWindowControlLayoutData.zero;
  Future<void>? _scheduledRefresh;
  int _latestRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scheduleRefresh());
    });
  }

  @override
  void dispose() {
    _latestRequestId++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    unawaited(_scheduleRefresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_scheduleRefresh());
    }
  }

  Future<void> _scheduleRefresh() =>
      _scheduledRefresh ??= Future<void>.microtask(() async {
        _scheduledRefresh = null;
        await _refresh();
      });

  Future<void> _refresh() async {
    final requestId = ++_latestRequestId;
    try {
      final data = await IosWindowControlLayoutPlatform.instance.query();
      if (!mounted || requestId != _latestRequestId || data == _data) {
        return;
      }
      setState(() => _data = data);
    } catch (error, stackTrace) {
      if (!mounted || requestId != _latestRequestId) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ios_window_control_layout',
          context: ErrorDescription(
            'while refreshing the iOS window-control layout',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _InheritedWindowControlLayout(
    data: _data,
    refresh: _scheduleRefresh,
    child: widget.child,
  );
}

class _InheritedWindowControlLayout extends InheritedWidget {
  const _InheritedWindowControlLayout({
    required this.data,
    required this.refresh,
    required super.child,
  });

  final IosWindowControlLayoutData data;
  final Future<void> Function() refresh;

  @override
  bool updateShouldNotify(_InheritedWindowControlLayout oldWidget) =>
      data != oldWidget.data;
}
