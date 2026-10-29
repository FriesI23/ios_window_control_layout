import 'dart:async';
import 'dart:ui' show DisplayFeature, FlutterView;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'layout_data.dart';
import 'platform.dart';

/// Provides UIKit's corner-adapted margins and safe areas to descendants.
///
/// The layout refreshes after its first frame, when Flutter reports new window
/// metrics, when the application resumes, and when native system occlusions
/// change. Place one owner above the application navigators. Call [refresh] when an
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

  /// Queries the layout margins and safe areas for the current Flutter view.
  ///
  /// Unsupported platforms return [IosWindowControlLayoutData.zero]. On iOS
  /// versions before iOS 26, device and window state remain populated while
  /// layout-region values are unavailable and zero. Native integration
  /// failures are surfaced as platform exceptions.
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
  StreamSubscription<void>? _occlusionSubscription;
  int _latestRequestId = 0;
  _OcclusionViewGeometry? _viewGeometry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _occlusionSubscription = IosWindowControlLayoutPlatform
        .instance
        .occlusionChanges
        .listen(
          (_) {
            _invalidateOcclusion();
            unawaited(_scheduleRefresh());
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) return;
            _invalidateOcclusion();
            _reportError(
              error,
              stackTrace,
              'while observing system occlusions',
            );
          },
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scheduleRefresh());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final previous = _viewGeometry;
    final view = View.of(context);
    if (previous != null && identical(previous.view, view)) return;
    _viewGeometry = _OcclusionViewGeometry.fromView(view);
    if (previous != null) {
      _invalidateOcclusion();
      unawaited(_scheduleRefresh());
    }
  }

  @override
  void dispose() {
    _latestRequestId++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_occlusionSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final previous = _viewGeometry;
    final current = previous == null
        ? null
        : _OcclusionViewGeometry.fromView(previous.view);
    if (current == null || current != previous) {
      _viewGeometry = current;
      _invalidateOcclusion();
    }
    // Refresh every notification, but discard valid geometry only when its
    // coordinate or protection inputs change. Presentation preferences and
    // derived viewport insets do not change the root-view coordinate space.
    unawaited(_scheduleRefresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _invalidateOcclusion();
      unawaited(_scheduleRefresh());
    }
  }

  Future<void> _scheduleRefresh() =>
      _scheduledRefresh ??= Future<void>.microtask(() async {
        _scheduledRefresh = null;
        if (mounted) await _refresh();
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
      _clearOcclusion();
      _reportError(
        error,
        stackTrace,
        'while refreshing the iOS window-control layout',
      );
    }
  }

  void _invalidateOcclusion() {
    if (!mounted) return;
    // Even an empty snapshot can have a pre-invalidation query in flight.
    _latestRequestId++;
    _clearOcclusion();
  }

  void _clearOcclusion() {
    if (_data.occlusionGeometry == null) return;
    setState(() => _data = _data.withoutOcclusionGeometry());
  }

  void _reportError(Object error, StackTrace stackTrace, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ios_window_control_layout',
        context: ErrorDescription(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedWindowControlLayout(
    data: _data,
    refresh: _scheduleRefresh,
    child: widget.child,
  );
}

// Only inputs that establish the coordinate space or its protection belong
// here. Native region changes have their own invalidation channel. In particular,
// MediaQuery presentation preferences and temporary viewInsets are not geometry.
class _OcclusionViewGeometry {
  _OcclusionViewGeometry._({
    required this.view,
    required this.size,
    required this.devicePixelRatio,
    required this.viewPadding,
    required this.independentPadding,
    required this.systemGestureInsets,
    required List<DisplayFeature> displayFeatures,
  }) : displayFeatures = List<DisplayFeature>.unmodifiable(displayFeatures);

  factory _OcclusionViewGeometry.fromView(FlutterView view) {
    final metrics = MediaQueryData.fromView(view);
    return _OcclusionViewGeometry._(
      view: view,
      size: metrics.size,
      devicePixelRatio: metrics.devicePixelRatio,
      viewPadding: metrics.viewPadding,
      independentPadding: EdgeInsets.fromLTRB(
        _paddingResidual(
          metrics.padding.left,
          metrics.viewPadding.left,
          metrics.viewInsets.left,
        ),
        _paddingResidual(
          metrics.padding.top,
          metrics.viewPadding.top,
          metrics.viewInsets.top,
        ),
        _paddingResidual(
          metrics.padding.right,
          metrics.viewPadding.right,
          metrics.viewInsets.right,
        ),
        _paddingResidual(
          metrics.padding.bottom,
          metrics.viewPadding.bottom,
          metrics.viewInsets.bottom,
        ),
      ),
      systemGestureInsets: metrics.systemGestureInsets,
      displayFeatures: metrics.displayFeatures,
    );
  }

  final FlutterView view;
  final Size size;
  final double devicePixelRatio;
  final EdgeInsets viewPadding;
  final EdgeInsets independentPadding;
  final EdgeInsets systemGestureInsets;
  final List<DisplayFeature> displayFeatures;

  static double _paddingResidual(
    double padding,
    double viewPadding,
    double inset,
  ) {
    final remaining = viewPadding - inset;
    final residual = padding - (remaining > 0 ? remaining : 0.0);
    // Normal derived padding is not an independent protection change. Remove
    // only arithmetic noise from conversion of physical pixels to points.
    return residual.abs() <= 0.000001 ? 0.0 : residual;
  }

  @override
  bool operator ==(Object other) =>
      other is _OcclusionViewGeometry &&
      identical(other.view, view) &&
      other.size == size &&
      other.devicePixelRatio == devicePixelRatio &&
      other.viewPadding == viewPadding &&
      other.independentPadding == independentPadding &&
      other.systemGestureInsets == systemGestureInsets &&
      listEquals(other.displayFeatures, displayFeatures);

  @override
  int get hashCode => Object.hash(
    identityHashCode(view),
    size,
    devicePixelRatio,
    viewPadding,
    independentPadding,
    systemGestureInsets,
    Object.hashAll(displayFeatures),
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
