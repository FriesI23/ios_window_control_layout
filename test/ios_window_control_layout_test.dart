import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
import 'package:ios_window_control_layout/src/platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class _FakePlatform
    with MockPlatformInterfaceMixin
    implements IosWindowControlLayoutPlatform {
  _FakePlatform(this.queryCallback);

  final Future<IosWindowControlLayoutData> Function() queryCallback;

  @override
  Stream<void> get occlusionChanges => const Stream<void>.empty();

  @override
  Future<IosWindowControlLayoutData> query() => queryCallback();
}

final class _InheritedPlatform extends IosWindowControlLayoutPlatform {
  _InheritedPlatform() : super.base();

  @override
  Stream<void> get occlusionChanges => const Stream<void>.empty();

  @override
  Future<IosWindowControlLayoutData> query() async =>
      IosWindowControlLayoutData.zero;
}

final class _UnverifiedPlatform implements IosWindowControlLayoutPlatform {
  @override
  Stream<void> get occlusionChanges => const Stream<void>.empty();

  @override
  Future<IosWindowControlLayoutData> query() async =>
      IosWindowControlLayoutData.zero;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = IosWindowControlLayoutPlatform.instance;

  tearDown(() {
    IosWindowControlLayoutPlatform.instance = initialPlatform;
  });

  test('platform factory returns zero outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final platform = IosWindowControlLayoutPlatform();
    expect(await platform.query(), IosWindowControlLayoutData.zero);
    expect(await platform.occlusionChanges.toList(), isEmpty);
  });

  test('platform instance accepts an inherited backend', () {
    final platform = _InheritedPlatform();

    IosWindowControlLayoutPlatform.instance = platform;

    expect(IosWindowControlLayoutPlatform.instance, same(platform));
  });

  test('platform instance rejects an unverified implementation', () {
    final previous = IosWindowControlLayoutPlatform.instance;

    expect(
      () => IosWindowControlLayoutPlatform.instance = _UnverifiedPlatform(),
      throwsA(isA<AssertionError>()),
    );
    expect(IosWindowControlLayoutPlatform.instance, same(previous));
  });

  test('avoidance is the non-negative adapted margin difference', () {
    const data = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.fromLTRB(16, 12, 20, 8),
      horizontalMargins: EdgeInsets.fromLTRB(72, 10, 18, 8),
      verticalMargins: EdgeInsets.fromLTRB(16, 52, 20, 6),
      baseSafeArea: EdgeInsets.fromLTRB(4, 6, 8, 10),
      horizontalSafeArea: EdgeInsets.fromLTRB(34, 4, 6, 10),
      verticalSafeArea: EdgeInsets.fromLTRB(2, 46, 8, 8),
      effectiveCornerRadii: BorderRadius.all(Radius.circular(62)),
    );

    expect(data.horizontalAvoidance, const EdgeInsets.fromLTRB(56, 0, 0, 0));
    expect(data.verticalAvoidance, const EdgeInsets.fromLTRB(0, 40, 0, 0));
    expect(data.hasAvoidance, isTrue);
    expect(data.horizontalAvoidance, const EdgeInsets.only(left: 56));
    expect(
      data.horizontalSafeAreaAvoidance,
      const EdgeInsets.fromLTRB(30, 0, 0, 0),
    );
    expect(
      data.verticalSafeAreaAvoidance,
      const EdgeInsets.fromLTRB(0, 40, 0, 0),
    );
  });

  testWidgets('physical avoidance does not flip with Flutter directionality', (
    tester,
  ) async {
    const data = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.zero,
      horizontalMargins: EdgeInsets.only(left: 40, right: 12),
      verticalMargins: EdgeInsets.zero,
    );
    const contentKey = ValueKey('physical-content');

    Future<Rect> layout(TextDirection direction) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: direction,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: Padding(
                padding: data.horizontalAvoidance,
                child: const SizedBox(key: contentKey, height: 20),
              ),
            ),
          ),
        ),
      );
      return tester.getRect(find.byKey(contentKey));
    }

    final ltrRect = await layout(TextDirection.ltr);
    final rtlRect = await layout(TextDirection.rtl);

    expect(rtlRect, ltrRect);
    expect(ltrRect.left, 40);
    expect(ltrRect.width, 148);
  });

  test('zero data is unavailable and has no avoidance', () {
    expect(IosWindowControlLayoutData.zero.isAvailable, isFalse);
    expect(IosWindowControlLayoutData.zero.isPad, isFalse);
    expect(IosWindowControlLayoutData.zero.isFullScreen, isTrue);
    expect(IosWindowControlLayoutData.zero.hasAvoidance, isFalse);
    expect(IosWindowControlLayoutData.zero.hasWindowControlAvoidance, isFalse);
    expect(IosWindowControlLayoutData.zero.baseSafeArea, EdgeInsets.zero);
    expect(
      IosWindowControlLayoutData.zero.horizontalSafeAreaAvoidance,
      EdgeInsets.zero,
    );
    expect(
      IosWindowControlLayoutData.zero.verticalSafeAreaAvoidance,
      EdgeInsets.zero,
    );
    expect(
      IosWindowControlLayoutData.zero.effectiveCornerRadii,
      BorderRadius.zero,
    );
  });

  test('window-control avoidance requires an available windowed iPad', () {
    IosWindowControlLayoutData data({
      required bool isAvailable,
      required bool isPad,
      required bool isFullScreen,
    }) => IosWindowControlLayoutData(
      isAvailable: isAvailable,
      isPad: isPad,
      isFullScreen: isFullScreen,
      baseMargins: EdgeInsets.zero,
      horizontalMargins: const EdgeInsets.only(left: 40),
      verticalMargins: EdgeInsets.zero,
    );

    expect(
      data(
        isAvailable: true,
        isPad: false,
        isFullScreen: true,
      ).hasWindowControlAvoidance,
      isFalse,
      reason: 'iPhone corner adaptation is not a window-control region',
    );
    expect(
      data(
        isAvailable: true,
        isPad: true,
        isFullScreen: true,
      ).hasWindowControlAvoidance,
      isFalse,
      reason: 'fullscreen iPad has no windowed controls',
    );
    expect(
      data(
        isAvailable: true,
        isPad: true,
        isFullScreen: false,
      ).hasWindowControlAvoidance,
      isTrue,
    );
    expect(
      data(
        isAvailable: false,
        isPad: true,
        isFullScreen: false,
      ).hasWindowControlAvoidance,
      isFalse,
    );
  });

  test('data has value equality', () {
    const first = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.all(8),
      horizontalMargins: EdgeInsets.all(16),
      verticalMargins: EdgeInsets.all(24),
      baseSafeArea: EdgeInsets.all(4),
      horizontalSafeArea: EdgeInsets.all(12),
      verticalSafeArea: EdgeInsets.all(20),
      effectiveCornerRadii: BorderRadius.all(Radius.circular(62)),
    );
    const second = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.all(8),
      horizontalMargins: EdgeInsets.all(16),
      verticalMargins: EdgeInsets.all(24),
      baseSafeArea: EdgeInsets.all(4),
      horizontalSafeArea: EdgeInsets.all(12),
      verticalSafeArea: EdgeInsets.all(20),
      effectiveCornerRadii: BorderRadius.all(Radius.circular(62)),
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(
      first,
      isNot(
        const IosWindowControlLayoutData(
          isAvailable: true,
          baseMargins: EdgeInsets.all(8),
          horizontalMargins: EdgeInsets.all(16),
          verticalMargins: EdgeInsets.all(24),
          baseSafeArea: EdgeInsets.all(5),
          horizontalSafeArea: EdgeInsets.all(12),
          verticalSafeArea: EdgeInsets.all(20),
          effectiveCornerRadii: BorderRadius.all(Radius.circular(61)),
        ),
      ),
    );
    expect(first.toString(), contains('baseSafeArea:'));
    expect(first.toString(), contains('horizontalSafeArea:'));
    expect(first.toString(), contains('verticalSafeArea:'));
    expect(first.toString(), contains('effectiveCornerRadii:'));
  });

  test('low-level query delegates to the platform implementation', () async {
    IosWindowControlLayoutPlatform.instance = _FakePlatform(
      () async => IosWindowControlLayoutData.zero,
    );

    expect(
      await IosWindowControlLayout.query(),
      IosWindowControlLayoutData.zero,
    );
  });

  testWidgets('layout queries after the first frame and notifies dependents', (
    tester,
  ) async {
    const updated = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.all(8),
      horizontalMargins: EdgeInsets.fromLTRB(40, 8, 8, 8),
      verticalMargins: EdgeInsets.fromLTRB(8, 40, 8, 8),
      baseSafeArea: EdgeInsets.all(4),
      horizontalSafeArea: EdgeInsets.fromLTRB(24, 4, 4, 4),
      verticalSafeArea: EdgeInsets.all(4),
    );
    var queryCount = 0;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(() async {
      queryCount++;
      return updated;
    });

    await tester.pumpWidget(
      const MaterialApp(home: IosWindowControlLayout(child: _LayoutValue())),
    );
    expect(find.text('false:false:true:0.0:0.0'), findsOneWidget);

    await tester.pump();
    expect(queryCount, 1);
    expect(find.text('true:false:true:32.0:20.0'), findsOneWidget);
  });

  testWidgets('explicit refresh coalesces calls in the same microtask', (
    tester,
  ) async {
    var queryCount = 0;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(() async {
      queryCount++;
      return IosWindowControlLayoutData.zero;
    });
    late BuildContext layoutContext;

    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(queryCount, 1);

    final first = IosWindowControlLayout.refresh(layoutContext);
    final second = IosWindowControlLayout.refresh(layoutContext);
    await tester.pump();
    await Future.wait([first, second]);

    expect(queryCount, 2);
  });

  testWidgets('metrics changes and resume request a refresh', (tester) async {
    var queryCount = 0;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(() async {
      queryCount++;
      return IosWindowControlLayoutData.zero;
    });

    await tester.pumpWidget(
      const MaterialApp(home: IosWindowControlLayout(child: SizedBox())),
    );
    await tester.pump();
    expect(queryCount, 1);

    tester.binding.handleMetricsChanged();
    await tester.pump();
    expect(queryCount, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(queryCount, 3);
  });

  testWidgets('metrics refreshes windowed and fullscreen state changes', (
    tester,
  ) async {
    var isFullScreen = false;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(
      () async => IosWindowControlLayoutData(
        isAvailable: true,
        isPad: true,
        isFullScreen: isFullScreen,
        baseMargins: EdgeInsets.zero,
        horizontalMargins: const EdgeInsets.only(left: 40),
        verticalMargins: EdgeInsets.zero,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: IosWindowControlLayout(child: _LayoutValue())),
    );
    await tester.pump();
    expect(find.text('true:true:false:40.0:0.0'), findsOneWidget);

    isFullScreen = true;
    tester.binding.handleMetricsChanged();
    await tester.pump();
    expect(find.text('true:true:true:40.0:0.0'), findsOneWidget);

    isFullScreen = false;
    tester.binding.handleMetricsChanged();
    await tester.pump();
    expect(find.text('true:true:false:40.0:0.0'), findsOneWidget);
  });

  testWidgets('a stale query cannot replace a newer result', (tester) async {
    final first = Completer<IosWindowControlLayoutData>();
    final second = Completer<IosWindowControlLayoutData>();
    var queryCount = 0;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(() {
      queryCount++;
      return queryCount == 1 ? first.future : second.future;
    });
    late BuildContext layoutContext;

    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              final data = IosWindowControlLayout.of(context);
              return Text('${data.baseMargins.left}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final refresh = IosWindowControlLayout.refresh(layoutContext);
    await tester.pump();

    second.complete(
      const IosWindowControlLayoutData(
        isAvailable: true,
        baseMargins: EdgeInsets.all(20),
        horizontalMargins: EdgeInsets.all(20),
        verticalMargins: EdgeInsets.all(20),
      ),
    );
    await refresh;
    await tester.pump();
    first.complete(
      const IosWindowControlLayoutData(
        isAvailable: true,
        baseMargins: EdgeInsets.all(10),
        horizontalMargins: EdgeInsets.all(10),
        verticalMargins: EdgeInsets.all(10),
      ),
    );
    await tester.pump();

    expect(find.text('20.0'), findsOneWidget);
  });

  testWidgets('read does not rebuild while of does', (tester) async {
    var current = IosWindowControlLayoutData.zero;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(
      () async => current,
    );
    var dependentBuilds = 0;
    var readBuilds = 0;
    late BuildContext layoutContext;

    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              return Column(
                children: [
                  Builder(
                    builder: (context) {
                      dependentBuilds++;
                      IosWindowControlLayout.of(context);
                      return const SizedBox();
                    },
                  ),
                  Builder(
                    builder: (context) {
                      readBuilds++;
                      IosWindowControlLayout.read(context);
                      return const SizedBox();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(dependentBuilds, 1);
    expect(readBuilds, 1);

    current = const IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.all(8),
      horizontalMargins: EdgeInsets.all(8),
      verticalMargins: EdgeInsets.all(8),
    );
    await IosWindowControlLayout.refresh(layoutContext);
    await tester.pump();

    expect(dependentBuilds, 2);
    expect(readBuilds, 1);
  });

  testWidgets('refresh errors preserve the last valid snapshot', (
    tester,
  ) async {
    const valid = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsets.all(12),
      horizontalMargins: EdgeInsets.all(12),
      verticalMargins: EdgeInsets.all(12),
    );
    var shouldFail = false;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(() async {
      if (shouldFail) throw StateError('query failed');
      return valid;
    });
    late BuildContext layoutContext;

    await tester.pumpWidget(
      MaterialApp(
        home: IosWindowControlLayout(
          child: Builder(
            builder: (context) {
              layoutContext = context;
              final data = IosWindowControlLayout.of(context);
              return Text('${data.baseMargins.left}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('12.0'), findsOneWidget);

    final previousErrorHandler = FlutterError.onError;
    FlutterErrorDetails? reportedError;
    FlutterError.onError = (details) => reportedError = details;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    shouldFail = true;

    await IosWindowControlLayout.refresh(layoutContext);
    await tester.pump();

    expect(find.text('12.0'), findsOneWidget);
    expect(reportedError?.exception, isA<StateError>());
  });
}

class _LayoutValue extends StatelessWidget {
  const _LayoutValue();

  @override
  Widget build(BuildContext context) {
    final data = IosWindowControlLayout.of(context);
    return Text(
      '${data.isAvailable}:${data.isPad}:${data.isFullScreen}:'
      '${data.horizontalAvoidance.left}:'
      '${data.horizontalSafeAreaAvoidance.left}',
    );
  }
}
