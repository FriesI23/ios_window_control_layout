import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
import 'package:ios_window_control_layout/src/platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _GeometryPlatform
    with MockPlatformInterfaceMixin
    implements IosWindowControlLayoutPlatform {
  _GeometryPlatform(this.queryCallback, [this.changes = const Stream.empty()]);

  final Future<IosWindowControlLayoutData> Function() queryCallback;
  final Stream<void> changes;

  @override
  Future<IosWindowControlLayoutData> query() => queryCallback();

  @override
  Stream<void> get occlusionChanges => changes;
}

IosWindowControlLayoutData _geometry({double columnTop = 174}) =>
    IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: const EdgeInsets.all(16),
      horizontalMargins: const EdgeInsets.all(16),
      verticalMargins: const EdgeInsets.all(16),
      baseSafeArea: const EdgeInsets.only(right: 84, bottom: 34),
      occlusionGeometry: IosOcclusionGeometry(
        viewBounds: const Rect.fromLTWH(0, 0, 466, 678),
        activeOcclusionRegions: const [Rect.fromLTWH(382, 0, 84, 174)],
        hasVerticalSystemBar: true,
        verticalBarLayoutFrame: Rect.fromLTRB(396, columnTop, 440, 644),
      ),
    );

Future<BuildContext> _mountOwner(
  WidgetTester tester, {
  required Future<IosWindowControlLayoutData> Function() query,
  Stream<void> changes = const Stream.empty(),
  VoidCallback? onBuild,
}) async {
  IosWindowControlLayoutPlatform.instance = _GeometryPlatform(query, changes);
  late BuildContext context;
  await tester.pumpWidget(
    IosWindowControlLayout(
      child: Builder(
        builder: (value) {
          context = value;
          IosWindowControlLayout.of(value);
          onBuild?.call();
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  return context;
}

void _metricsFrame(WidgetTester tester, VoidCallback update) {
  // The engine publishes metrics together; test setters notify individually.
  final dispatcher = tester.binding.platformDispatcher;
  dispatcher.onMetricsChanged = null;
  try {
    update();
  } finally {
    dispatcher.onMetricsChanged = tester.binding.handleMetricsChanged;
  }
  tester.binding.handleMetricsChanged();
}

void _insetsFrame(WidgetTester tester, EdgeInsets insets) {
  _metricsFrame(tester, () {
    tester.view.viewInsets = FakeViewPadding(
      left: insets.left,
      top: insets.top,
      right: insets.right,
      bottom: insets.bottom,
    );
    final padding = tester.view.viewPadding;
    tester.view.padding = FakeViewPadding(
      left: math.max(0, padding.left - insets.left),
      top: math.max(0, padding.top - insets.top),
      right: math.max(0, padding.right - insets.right),
      bottom: math.max(0, padding.bottom - insets.bottom),
    );
  });
}

void main() {
  final initialPlatform = IosWindowControlLayoutPlatform.instance;
  tearDown(() => IosWindowControlLayoutPlatform.instance = initialPlatform);

  for (final pixelRatio in [1.0, 3.0]) {
    testWidgets(
      'derived insets on every edge keep geometry at DPR $pixelRatio',
      (tester) async {
        tester.view.devicePixelRatio = pixelRatio;
        tester.view.physicalSize = Size(466 * pixelRatio, 678 * pixelRatio);
        // Nonintegral logical padding exercises division roundoff at DPR 3.
        final edge = 34 * pixelRatio + (pixelRatio == 3 ? 1 : 0);
        tester.view.viewPadding = FakeViewPadding(
          left: edge,
          top: edge,
          right: edge,
          bottom: edge,
        );
        tester.view.padding = tester.view.viewPadding;
        addTearDown(tester.view.reset);
        final pending = Completer<IosWindowControlLayoutData>();
        final initial = _geometry();
        var queries = 0;
        var builds = 0;
        final context = await _mountOwner(
          tester,
          query: () => ++queries == 1 ? Future.value(initial) : pending.future,
          onBuild: () => builds++,
        );
        final beforeBuilds = builds;
        for (final insets in [
          EdgeInsets.only(left: 8 * pixelRatio),
          EdgeInsets.only(top: 60 * pixelRatio),
          EdgeInsets.only(right: 20 * pixelRatio),
          EdgeInsets.only(bottom: 320 * pixelRatio),
          EdgeInsets.all(12 * pixelRatio),
          EdgeInsets.zero,
        ]) {
          _insetsFrame(tester, insets);
          await tester.pump();
          expect(
            IosWindowControlLayout.read(context).occlusionGeometry,
            same(initial.occlusionGeometry),
            reason: 'derived $insets do not change root-view geometry',
          );
        }
        expect(queries, 7, reason: 'every metrics notification still queries');
        expect(builds, beforeBuilds);
        pending.complete(initial);
        await tester.pumpAndSettle();
        expect(builds, beforeBuilds);
      },
    );
  }

  for (final preference in [
    'brightness',
    'text scale',
    'accessibility',
    '24-hour format',
    'combined',
  ]) {
    testWidgets('$preference followed by metrics keeps valid geometry', (
      tester,
    ) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.platformBrightnessTestValue = Brightness.light;
      dispatcher.textScaleFactorTestValue = 1;
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      dispatcher.alwaysUse24HourFormatTestValue = false;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);
      addTearDown(dispatcher.clearTextScaleFactorTestValue);
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      addTearDown(dispatcher.clearAlwaysUse24HourTestValue);
      addTearDown(tester.view.reset);
      final pending = Completer<IosWindowControlLayoutData>();
      final initial = _geometry();
      var queries = 0;
      var builds = 0;
      final context = await _mountOwner(
        tester,
        query: () => ++queries == 1 ? Future.value(initial) : pending.future,
        onBuild: () => builds++,
      );
      final before = MediaQueryData.fromView(tester.view);
      final beforeBuilds = builds;
      if (preference == 'brightness' || preference == 'combined') {
        dispatcher.platformBrightnessTestValue = Brightness.dark;
      }
      if (preference == 'text scale' || preference == 'combined') {
        dispatcher.textScaleFactorTestValue = 1.5;
      }
      if (preference == 'accessibility' || preference == 'combined') {
        dispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(highContrast: true, boldText: true);
      }
      if (preference == '24-hour format' || preference == 'combined') {
        dispatcher.alwaysUse24HourFormatTestValue = true;
      }
      await tester.pump();
      final after = MediaQueryData.fromView(tester.view);
      expect(after.size, before.size);
      expect(after.devicePixelRatio, before.devicePixelRatio);
      expect(after.padding, before.padding);
      expect(after.viewPadding, before.viewPadding);
      expect(after.viewInsets, before.viewInsets);
      expect(queries, 1);
      for (var event = 0; event < 3; event++) {
        tester.binding.handleMetricsChanged();
        await tester.pump();
        expect(
          IosWindowControlLayout.read(context).occlusionGeometry,
          same(initial.occlusionGeometry),
        );
      }
      expect(queries, 4);
      expect(builds, beforeBuilds);
      pending.complete(initial);
      await tester.pumpAndSettle();
      expect(builds, beforeBuilds);
    });
  }

  for (final metric in [
    'bounds',
    'pixel ratio',
    'view padding',
    'independent horizontal padding',
    'independent bottom padding',
    'gestures',
    'display features',
  ]) {
    testWidgets('$metric changes invalidate before the native reply', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(466, 678);
      tester.view.viewPadding = const FakeViewPadding(right: 84, bottom: 34);
      tester.view.padding = tester.view.viewPadding;
      addTearDown(tester.view.reset);
      final pending = Completer<IosWindowControlLayoutData>();
      var queries = 0;
      final context = await _mountOwner(
        tester,
        query: () =>
            ++queries == 1 ? Future.value(_geometry()) : pending.future,
      );
      _insetsFrame(tester, const EdgeInsets.only(bottom: 320));
      await tester.pump();
      expect(IosWindowControlLayout.read(context).occlusionGeometry, isNotNull);
      _metricsFrame(tester, () {
        switch (metric) {
          case 'bounds':
            tester.view.physicalSize = const Size(467, 678);
          case 'pixel ratio':
            tester.view.devicePixelRatio = 2;
          case 'view padding':
            tester.view.viewPadding = const FakeViewPadding(
              right: 84,
              bottom: 35,
            );
          case 'independent horizontal padding':
            tester.view.padding = const FakeViewPadding(right: 85);
          case 'independent bottom padding':
            tester.view.padding = const FakeViewPadding(right: 84, bottom: 1);
          case 'gestures':
            tester.view.systemGestureInsets = const FakeViewPadding(bottom: 40);
          case 'display features':
            tester.view.displayFeatures = const [
              DisplayFeature(
                bounds: Rect.fromLTWH(232, 0, 2, 678),
                type: DisplayFeatureType.hinge,
                state: DisplayFeatureState.postureFlat,
              ),
            ];
        }
      });
      await tester.pump();
      expect(IosWindowControlLayout.read(context).occlusionGeometry, isNull);
      expect(IosWindowControlLayout.read(context).baseMargins.left, 16);
      pending.complete(_geometry());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('equivalent display-feature lists do not discard geometry', (
    tester,
  ) async {
    final features = <DisplayFeature>[
      const DisplayFeature(
        bounds: Rect.fromLTWH(232, 0, 2, 678),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
    ];
    tester.view.displayFeatures = features;
    addTearDown(tester.view.reset);
    final pending = Completer<IosWindowControlLayoutData>();
    final initial = _geometry();
    var queries = 0;
    final context = await _mountOwner(
      tester,
      query: () => ++queries == 1 ? Future.value(initial) : pending.future,
    );
    tester.view.displayFeatures = List.of(features);
    await tester.pump();
    expect(
      IosWindowControlLayout.read(context).occlusionGeometry,
      same(initial.occlusionGeometry),
    );
    pending.complete(initial);
    await tester.pumpAndSettle();
  });

  testWidgets('corner-only native updates keep the same valid geometry', (
    tester,
  ) async {
    final initial = _geometry();
    final pending = Completer<IosWindowControlLayoutData>();
    var queries = 0;
    final context = await _mountOwner(
      tester,
      query: () => ++queries == 1 ? Future.value(initial) : pending.future,
    );
    tester.binding.handleMetricsChanged();
    await tester.pump();
    expect(
      IosWindowControlLayout.read(context).occlusionGeometry,
      same(initial.occlusionGeometry),
    );
    const corners = BorderRadius.all(Radius.circular(32));
    pending.complete(
      IosWindowControlLayoutData(
        isAvailable: initial.isAvailable,
        baseMargins: initial.baseMargins,
        horizontalMargins: initial.horizontalMargins,
        verticalMargins: initial.verticalMargins,
        baseSafeArea: initial.baseSafeArea,
        effectiveCornerRadii: corners,
        occlusionGeometry: initial.occlusionGeometry,
      ),
    );
    await tester.pumpAndSettle();
    final current = IosWindowControlLayout.read(context);
    expect(current.effectiveCornerRadii, corners);
    expect(current.occlusionGeometry, same(initial.occlusionGeometry));
  });

  testWidgets('native changes reject pre-event queries during inset changes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    tester.view.viewPadding = const FakeViewPadding(right: 84, bottom: 34);
    tester.view.padding = tester.view.viewPadding;
    addTearDown(tester.view.reset);
    final changes = StreamController<void>.broadcast(sync: true);
    addTearDown(changes.close);
    final beforeEvent = Completer<IosWindowControlLayoutData>();
    final afterEvent = Completer<IosWindowControlLayoutData>();
    var queries = 0;
    final context = await _mountOwner(
      tester,
      query: () => switch (++queries) {
        1 => Future.value(_geometry()),
        2 => beforeEvent.future,
        _ => afterEvent.future,
      },
      changes: changes.stream,
    );
    _insetsFrame(tester, const EdgeInsets.only(left: 8, bottom: 320));
    await tester.pump();
    expect(IosWindowControlLayout.read(context).occlusionGeometry, isNotNull);
    changes.add(null);
    await tester.pump();
    expect(IosWindowControlLayout.read(context).occlusionGeometry, isNull);
    beforeEvent.complete(_geometry());
    await tester.pump();
    expect(IosWindowControlLayout.read(context).occlusionGeometry, isNull);
    final current = _geometry(columnTop: 200);
    afterEvent.complete(current);
    await tester.pumpAndSettle();
    expect(IosWindowControlLayout.read(context), current);
  });
}
