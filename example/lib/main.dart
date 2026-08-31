import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';

const _toolbarEdgePadding = 16.0;
const _bottomControlMargin = 12.0;

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return IosWindowControlLayout(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const _ExamplePage(),
      ),
    );
  }
}

enum _AppBarStyle { material, cupertino }

class _ExamplePage extends StatefulWidget {
  const _ExamplePage();

  @override
  State<_ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<_ExamplePage> {
  _AppBarStyle _style = _AppBarStyle.cupertino;
  bool _applyWindowControlLayout = true;

  @override
  Widget build(BuildContext context) {
    final data = IosWindowControlLayout.of(context);
    final flutterSafeArea = MediaQuery.paddingOf(context);
    final avoidance = _applyWindowControlLayout
        ? data.horizontalAvoidance
        : EdgeInsetsDirectional.zero;
    final bottomControlPadding = _applyWindowControlLayout
        ? _bottomBoundaryPadding(
            flutterSafeArea: flutterSafeArea,
            verticalSafeArea: data.verticalSafeArea,
            cornerRadii: data.effectiveCornerRadii,
          )
        : EdgeInsets.zero;
    return Scaffold(
      appBar: switch (_style) {
        _AppBarStyle.material => _buildMaterialAppBar(context, avoidance),
        _AppBarStyle.cupertino => _buildCupertinoAppBar(context, avoidance),
      },
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    key: const ValueKey('select-material-app-bar'),
                    leadingIcon: const Icon(Icons.android),
                    onPressed: () => _selectStyle(_AppBarStyle.material),
                    child: const Text('Material AppBar'),
                  ),
                  MenuItemButton(
                    key: const ValueKey('select-cupertino-app-bar'),
                    leadingIcon: const Icon(
                      CupertinoIcons.device_phone_portrait,
                    ),
                    onPressed: () => _selectStyle(_AppBarStyle.cupertino),
                    child: const Text('Cupertino AppBar'),
                  ),
                ],
                builder: (context, controller, child) => FilledButton.tonalIcon(
                  key: const ValueKey('app-bar-style-menu'),
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  icon: const Icon(Icons.view_day_outlined),
                  label: Text(switch (_style) {
                    _AppBarStyle.material => 'Material AppBar',
                    _AppBarStyle.cupertino => 'Cupertino AppBar',
                  }),
                ),
              ),
            ),
            SwitchListTile(
              key: const ValueKey('apply-window-control-layout-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Apply window control layout'),
              subtitle: const Text(
                'Add the reported avoidance to the toolbar controls',
              ),
              value: _applyWindowControlLayout,
              onChanged: (value) {
                setState(() => _applyWindowControlLayout = value);
              },
            ),
            const SizedBox(height: 24),
            Text(
              data.isAvailable
                  ? 'UIKit layout regions available'
                  : 'UIKit layout regions unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Interface idiom: ${data.isPad ? 'iPad' : 'not iPad'}',
              key: const ValueKey('interface-idiom-status'),
            ),
            Text(
              'Window mode: ${data.isFullScreen ? 'fullscreen' : 'windowed'}',
              key: const ValueKey('window-mode-status'),
            ),
            Text(
              'iPad window-control avoidance: '
              '${data.hasWindowControlAvoidance ? 'present' : 'absent'}',
              key: const ValueKey('window-control-status'),
            ),
            Text('Reported horizontal avoidance: ${data.horizontalAvoidance}'),
            Text('Applied horizontal avoidance: $avoidance'),
            Text('Vertical avoidance: ${data.verticalAvoidance}'),
            Text('Adapted safe area: ${data.horizontalSafeArea}'),
            Text('Safe-area avoidance: ${data.horizontalSafeAreaAvoidance}'),
            Text('Effective corner radii: ${data.effectiveCornerRadii}'),
            Text('Flutter safe area: $flutterSafeArea'),
            const SizedBox(height: 24),
            _InsetsPreview(
              title: 'Horizontal avoidance preview',
              insets: avoidance,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            _InsetsPreview(
              title: 'Vertical avoidance preview',
              insets: data.verticalAvoidance,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            const Text(
              'The leading button and trailing refresh button are intentionally '
              'placed at the toolbar edges. Resize the iPad window to verify '
              'that both remain outside the system window controls and that '
              'the window mode above updates between fullscreen and windowed.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        key: const ValueKey('flutter-safe-area-color'),
        color: Colors.orange.withValues(alpha: 0.35),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              key: const ValueKey('bottom-boundary-padding'),
              padding: bottomControlPadding,
              child: Opacity(
                key: const ValueKey('uikit-floating-control'),
                opacity: 0.85,
                child: Card(
                  margin: const EdgeInsets.all(_bottomControlMargin),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Floating controls use UIKit bottom-corner geometry',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMaterialAppBar(
    BuildContext context,
    EdgeInsetsDirectional avoidance,
  ) {
    return AppBar(
      centerTitle: true,
      leadingWidth: kToolbarHeight + _toolbarEdgePadding + avoidance.start,
      leading: Padding(
        padding: EdgeInsetsDirectional.only(
          start: _toolbarEdgePadding + avoidance.start,
        ),
        child: IconButton(
          key: const ValueKey('material-leading'),
          tooltip: 'Leading test button',
          onPressed: () {},
          icon: const Icon(Icons.menu),
        ),
      ),
      title: const Text('Material'),
      actions: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: _toolbarEdgePadding + avoidance.end,
          ),
          child: IconButton(
            key: const ValueKey('material-trailing'),
            tooltip: 'Refresh layout',
            onPressed: () => unawaited(IosWindowControlLayout.refresh(context)),
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildCupertinoAppBar(
    BuildContext context,
    EdgeInsetsDirectional avoidance,
  ) {
    return CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      padding: EdgeInsetsDirectional.only(
        start: _toolbarEdgePadding + avoidance.start,
        end: _toolbarEdgePadding + avoidance.end,
      ),
      leading: CupertinoButton(
        key: const ValueKey('cupertino-leading'),
        padding: EdgeInsets.zero,
        onPressed: () {},
        child: const Icon(CupertinoIcons.sidebar_left),
      ),
      middle: const Text('Cupertino'),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => unawaited(IosWindowControlLayout.refresh(context)),
        child: const Icon(CupertinoIcons.refresh),
      ),
    );
  }

  void _selectStyle(_AppBarStyle style) {
    if (_style == style) return;
    setState(() => _style = style);
  }
}

EdgeInsets _bottomBoundaryPadding({
  required EdgeInsets flutterSafeArea,
  required EdgeInsetsDirectional verticalSafeArea,
  required BorderRadius cornerRadii,
}) {
  final adaptedBottom = math.max(
    flutterSafeArea.bottom,
    verticalSafeArea.bottom,
  );
  final distanceFromBottom = adaptedBottom + _bottomControlMargin;
  return EdgeInsets.only(
    left: math.max(
      0,
      _horizontalInsetAt(
            radius: cornerRadii.bottomLeft,
            distanceFromBottom: distanceFromBottom,
          ) -
          _bottomControlMargin,
    ),
    right: math.max(
      0,
      _horizontalInsetAt(
            radius: cornerRadii.bottomRight,
            distanceFromBottom: distanceFromBottom,
          ) -
          _bottomControlMargin,
    ),
    bottom: math.max(0, adaptedBottom - flutterSafeArea.bottom),
  );
}

double _horizontalInsetAt({
  required Radius radius,
  required double distanceFromBottom,
}) {
  if (radius.x <= 0 || radius.y <= 0 || distanceFromBottom >= radius.y) {
    return 0;
  }
  final normalizedY = (radius.y - distanceFromBottom) / radius.y;
  final normalizedX = math.sqrt(math.max(0, 1 - normalizedY * normalizedY));
  return radius.x * (1 - normalizedX);
}

class _InsetsPreview extends StatelessWidget {
  const _InsetsPreview({
    required this.title,
    required this.insets,
    required this.color,
  });

  final String title;
  final EdgeInsetsDirectional insets;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final resolved = insets.resolve(Directionality.of(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final leadingWidth = math.min(resolved.left, constraints.maxWidth);
            final trailingWidth = math.min(
              resolved.right,
              math.max(0.0, constraints.maxWidth - leadingWidth),
            );
            return Container(
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: leadingWidth, color: color),
                  const Expanded(child: Center(child: Text('safe content'))),
                  Container(width: trailingWidth, color: color),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
