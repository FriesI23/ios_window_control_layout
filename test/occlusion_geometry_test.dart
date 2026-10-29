import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
import 'package:ios_window_control_layout/src/platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class _OcclusionPlatform
    with MockPlatformInterfaceMixin
    implements IosWindowControlLayoutPlatform {
  _OcclusionPlatform(this.queryCallback, this.changes);

  final Future<IosWindowControlLayoutData> Function() queryCallback;
  final Stream<void> changes;

  @override
  Stream<void> get occlusionChanges => changes;

  @override
  Future<IosWindowControlLayoutData> query() => queryCallback();
}

IosWindowControlLayoutData _data({bool empty = false, double left = 12}) =>
    IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.all(left),
      horizontalMargins: const EdgeInsets.all(30),
      verticalMargins: const EdgeInsets.all(40),
      baseSafeArea: const EdgeInsets.only(bottom: 34),
      effectiveCornerRadii: const BorderRadius.all(Radius.circular(60)),
      occlusionGeometry: IosOcclusionGeometry(
        viewBounds: const Rect.fromLTWH(0, 0, 800, 600),
        activeOcclusionRegions: empty
            ? []
            : [const Rect.fromLTWH(720, 0, 80, 100)],
        hasVerticalSystemBar: true,
      ),
    );

void main() {
  final initialPlatform = IosWindowControlLayoutPlatform.instance;

  tearDown(() {
    IosWindowControlLayoutPlatform.instance = initialPlatform;
  });

  test('occlusion geometry copies its input and has value equality', () {
    final regions = [const Rect.fromLTWH(-10, 0, 80, 100)];
    final first = IosOcclusionGeometry(
      viewBounds: const Rect.fromLTWH(0, 0, 800, 600),
      activeOcclusionRegions: regions,
      hasVerticalSystemBar: true,
    );
    final second = IosOcclusionGeometry(
      viewBounds: first.viewBounds,
      activeOcclusionRegions: List.of(regions),
      hasVerticalSystemBar: true,
    );
    regions.clear();
    expect(first.activeOcclusionRegions, hasLength(1));
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(() => first.activeOcclusionRegions.clear(), throwsUnsupportedError);
    expect(_data(), _data());
    expect(_data().hashCode, _data().hashCode);
    expect(_data(), isNot(_data(empty: true)));
    expect(IosWindowControlLayoutData.zero.occlusionGeometry, isNull);
  });

  test('optional bar layout frame participates in geometry equality', () {
    final first = IosOcclusionGeometry(
      viewBounds: const Rect.fromLTWH(0, 0, 800, 600),
      activeOcclusionRegions: const [],
      hasVerticalSystemBar: true,
      verticalBarLayoutFrame: const Rect.fromLTWH(730, 124, 44, 442),
    );
    final same = IosOcclusionGeometry(
      viewBounds: first.viewBounds,
      activeOcclusionRegions: const [],
      hasVerticalSystemBar: true,
      verticalBarLayoutFrame: first.verticalBarLayoutFrame,
    );
    final changed = IosOcclusionGeometry(
      viewBounds: first.viewBounds,
      activeOcclusionRegions: const [],
      hasVerticalSystemBar: true,
      verticalBarLayoutFrame: const Rect.fromLTWH(720, 124, 44, 442),
    );
    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(changed));
    expect(first.toString(), contains('verticalBarLayoutFrame'));
  });

  test('clearing occlusion retains all other layout fields', () {
    final data = _data();
    final cleared = data.withoutOcclusionGeometry();
    expect(cleared.occlusionGeometry, isNull);
    expect(cleared.baseMargins, data.baseMargins);
    expect(cleared.horizontalMargins, data.horizontalMargins);
    expect(cleared.verticalMargins, data.verticalMargins);
    expect(cleared.baseSafeArea, data.baseSafeArea);
    expect(cleared.effectiveCornerRadii, data.effectiveCornerRadii);
    expect(cleared.withoutOcclusionGeometry(), same(cleared));
  });

  testWidgets('native changes invalidate immediately and coalesce queries', (
    tester,
  ) async {
    final changes = StreamController<void>.broadcast(sync: true);
    addTearDown(changes.close);
    final next = Completer<IosWindowControlLayoutData>();
    var queries = 0;
    IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(
      () => ++queries == 1 ? Future.value(_data()) : next.future,
      changes.stream,
    );
    late BuildContext layoutContext;
    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              IosWindowControlLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      IosWindowControlLayout.read(layoutContext).occlusionGeometry,
      isNotNull,
    );

    changes.add(null);
    changes.add(null);
    await tester.pump();
    expect(queries, 2);
    final invalidated = IosWindowControlLayout.read(layoutContext);
    expect(invalidated.occlusionGeometry, isNull);
    expect(invalidated.baseMargins.left, 12);

    next.complete(_data(empty: true));
    await tester.pumpAndSettle();
    expect(
      IosWindowControlLayout.read(
        layoutContext,
      ).occlusionGeometry!.activeOcclusionRegions,
      isEmpty,
    );
  });

  testWidgets('metrics discard geometry while keeping margins during a query', (
    tester,
  ) async {
    final next = Completer<IosWindowControlLayoutData>();
    var queries = 0;
    IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(
      () => ++queries == 1 ? Future.value(_data()) : next.future,
      const Stream.empty(),
    );
    late BuildContext layoutContext;
    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              IosWindowControlLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1800, 2400);
    await tester.pump();
    final data = IosWindowControlLayout.read(layoutContext);
    expect(data.occlusionGeometry, isNull);
    expect(data.baseMargins.left, 12);
    next.complete(_data());
    await tester.pump();
  });

  testWidgets('unchanged metrics refresh without invalidating geometry', (
    tester,
  ) async {
    final next = Completer<IosWindowControlLayoutData>();
    var queries = 0;
    var dependentBuilds = 0;
    final initial = _data(empty: true);
    IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(
      () => ++queries == 1 ? Future.value(initial) : next.future,
      const Stream.empty(),
    );
    late BuildContext layoutContext;
    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              IosWindowControlLayout.of(context);
              dependentBuilds++;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final beforeBuilds = dependentBuilds;
    for (var event = 0; event < 4; event++) {
      tester.binding.handleMetricsChanged();
      await tester.pump();
      expect(
        IosWindowControlLayout.read(layoutContext).occlusionGeometry,
        initial.occlusionGeometry,
        reason: 'a duplicate metrics notification has not moved this view',
      );
    }
    expect(queries, 5, reason: 'legacy window-control refreshes still run');
    expect(dependentBuilds, beforeBuilds);
    next.complete(initial);
    await tester.pumpAndSettle();
    expect(dependentBuilds, beforeBuilds);
  });

  for (final metric in ['pixel ratio', 'padding', 'view padding', 'gestures']) {
    testWidgets('$metric changes invalidate before the native reply', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      final next = Completer<IosWindowControlLayoutData>();
      var queries = 0;
      IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(
        () => ++queries == 1 ? Future.value(_data()) : next.future,
        const Stream.empty(),
      );
      late BuildContext layoutContext;
      await tester.pumpWidget(
        MaterialApp(
          home: IosWindowControlLayout(
            child: Builder(
              builder: (context) {
                layoutContext = context;
                IosWindowControlLayout.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        IosWindowControlLayout.read(layoutContext).occlusionGeometry,
        isNotNull,
      );
      switch (metric) {
        case 'pixel ratio':
          tester.view.devicePixelRatio = 2;
        case 'padding':
          tester.view.padding = const FakeViewPadding(right: 84);
        case 'view padding':
          tester.view.viewPadding = const FakeViewPadding(right: 84);
        case 'gestures':
          tester.view.systemGestureInsets = const FakeViewPadding(bottom: 40);
      }
      await tester.pump();
      expect(queries, 2);
      final invalidated = IosWindowControlLayout.read(layoutContext);
      expect(invalidated.occlusionGeometry, isNull);
      expect(invalidated.baseMargins.left, 12);
      next.complete(_data());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('query errors clear only the occlusion snapshot', (tester) async {
    var fail = false;
    IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(() async {
      if (fail) throw StateError('query failed');
      return _data();
    }, const Stream.empty());
    late BuildContext layoutContext;
    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              IosWindowControlLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    fail = true;
    final errors = <FlutterErrorDetails>[];
    final handler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = handler);
    await IosWindowControlLayout.refresh(layoutContext);
    await tester.pump();
    final data = IosWindowControlLayout.read(layoutContext);
    expect(data.occlusionGeometry, isNull);
    expect(data.baseMargins.left, 12);
    expect(
      data.effectiveCornerRadii,
      const BorderRadius.all(Radius.circular(60)),
    );
    expect(errors.single.exception, isA<StateError>());
  });

  testWidgets('event invalidates in-flight requests before they can publish', (
    tester,
  ) async {
    final changes = StreamController<void>.broadcast(sync: true);
    addTearDown(changes.close);
    final first = Completer<IosWindowControlLayoutData>();
    final second = Completer<IosWindowControlLayoutData>();
    var queries = 0;
    IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(
      () => ++queries == 1 ? first.future : second.future,
      changes.stream,
    );
    late BuildContext layoutContext;
    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              IosWindowControlLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    changes.add(null);
    first.complete(_data(left: 99));
    await tester.pump();
    expect(
      IosWindowControlLayout.read(layoutContext),
      IosWindowControlLayoutData.zero,
    );
    second.complete(_data(left: 22));
    await tester.pumpAndSettle();
    expect(IosWindowControlLayout.read(layoutContext).baseMargins.left, 22);
  });

  testWidgets('event errors invalidate geometry and reject pending responses', (
    tester,
  ) async {
    final changes = StreamController<void>.broadcast(sync: true);
    addTearDown(changes.close);
    final pending = Completer<IosWindowControlLayoutData>();
    var queries = 0;
    IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(
      () => ++queries == 1 ? Future.value(_data()) : pending.future,
      changes.stream,
    );
    late BuildContext layoutContext;
    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              IosWindowControlLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final refresh = IosWindowControlLayout.refresh(layoutContext);
    await tester.pump();
    final errors = <FlutterErrorDetails>[];
    final handler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = handler);
    changes.addError(StateError('events failed'), StackTrace.current);
    pending.complete(_data(left: 99));
    await refresh;
    await tester.pumpAndSettle();
    final data = IosWindowControlLayout.read(layoutContext);
    expect(data.occlusionGeometry, isNull);
    expect(data.baseMargins.left, 12);
    expect(errors.single.exception, isA<StateError>());
  });

  testWidgets('owner subscribes once and cancels on disposal', (tester) async {
    var listens = 0;
    var cancels = 0;
    var queries = 0;
    final changes = StreamController<void>.broadcast(
      onListen: () => listens++,
      onCancel: () => cancels++,
    );
    addTearDown(changes.close);
    IosWindowControlLayoutPlatform.instance = _OcclusionPlatform(() async {
      queries++;
      return _data();
    }, changes.stream);
    final rebuild = ValueNotifier(0);
    addTearDown(rebuild.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: rebuild,
          builder: (context, value, child) =>
              IosWindowControlLayout(child: Text('$value')),
        ),
      ),
    );
    await tester.pump();
    rebuild.value++;
    await tester.pump();
    expect(listens, 1);
    await tester.pumpWidget(const SizedBox());
    expect(cancels, 1);
    final before = queries;
    changes.add(null);
    await tester.pump();
    expect(queries, before);
  });
}
