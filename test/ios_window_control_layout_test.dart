import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
import 'package:ios_window_control_layout/src/platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class _FakePlatform extends IosWindowControlLayoutPlatform
    with MockPlatformInterfaceMixin {
  _FakePlatform(this.queryCallback);

  final Future<IosWindowControlLayoutData> Function() queryCallback;

  @override
  Future<IosWindowControlLayoutData> query() => queryCallback();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = IosWindowControlLayoutPlatform.instance;

  tearDown(() {
    IosWindowControlLayoutPlatform.instance = initialPlatform;
  });

  test('$MethodChannelIosWindowControlLayout is the default instance', () {
    expect(initialPlatform, isA<MethodChannelIosWindowControlLayout>());
  });

  test('avoidance is the non-negative adapted margin difference', () {
    const data = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsetsDirectional.fromSTEB(16, 12, 20, 8),
      horizontalMargins: EdgeInsetsDirectional.fromSTEB(72, 10, 18, 8),
      verticalMargins: EdgeInsetsDirectional.fromSTEB(16, 52, 20, 6),
    );

    expect(
      data.horizontalAvoidance,
      const EdgeInsetsDirectional.fromSTEB(56, 0, 0, 0),
    );
    expect(
      data.verticalAvoidance,
      const EdgeInsetsDirectional.fromSTEB(0, 40, 0, 0),
    );
    expect(data.hasAvoidance, isTrue);
    expect(
      data.horizontalAvoidance.resolve(TextDirection.rtl),
      const EdgeInsets.only(right: 56),
    );
  });

  test('zero data is unavailable and has no avoidance', () {
    expect(IosWindowControlLayoutData.zero.isAvailable, isFalse);
    expect(IosWindowControlLayoutData.zero.hasAvoidance, isFalse);
  });

  test('data has value equality', () {
    const first = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsetsDirectional.all(8),
      horizontalMargins: EdgeInsetsDirectional.all(16),
      verticalMargins: EdgeInsetsDirectional.all(24),
    );
    const second = IosWindowControlLayoutData(
      isAvailable: true,
      baseMargins: EdgeInsetsDirectional.all(8),
      horizontalMargins: EdgeInsetsDirectional.all(16),
      verticalMargins: EdgeInsetsDirectional.all(24),
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
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
      baseMargins: EdgeInsetsDirectional.all(8),
      horizontalMargins: EdgeInsetsDirectional.fromSTEB(40, 8, 8, 8),
      verticalMargins: EdgeInsetsDirectional.fromSTEB(8, 40, 8, 8),
    );
    var queryCount = 0;
    IosWindowControlLayoutPlatform.instance = _FakePlatform(() async {
      queryCount++;
      return updated;
    });

    await tester.pumpWidget(
      const MaterialApp(home: IosWindowControlLayout(child: _LayoutValue())),
    );
    expect(find.text('false:0.0'), findsOneWidget);

    await tester.pump();
    expect(queryCount, 1);
    expect(find.text('true:32.0'), findsOneWidget);
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
              return Text('${data.baseMargins.start}');
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
        baseMargins: EdgeInsetsDirectional.all(20),
        horizontalMargins: EdgeInsetsDirectional.all(20),
        verticalMargins: EdgeInsetsDirectional.all(20),
      ),
    );
    await refresh;
    await tester.pump();
    first.complete(
      const IosWindowControlLayoutData(
        isAvailable: true,
        baseMargins: EdgeInsetsDirectional.all(10),
        horizontalMargins: EdgeInsetsDirectional.all(10),
        verticalMargins: EdgeInsetsDirectional.all(10),
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
      baseMargins: EdgeInsetsDirectional.all(8),
      horizontalMargins: EdgeInsetsDirectional.all(8),
      verticalMargins: EdgeInsetsDirectional.all(8),
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
      baseMargins: EdgeInsetsDirectional.all(12),
      horizontalMargins: EdgeInsetsDirectional.all(12),
      verticalMargins: EdgeInsetsDirectional.all(12),
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
              return Text('${data.baseMargins.start}');
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
    return Text('${data.isAvailable}:${data.horizontalAvoidance.start}');
  }
}
