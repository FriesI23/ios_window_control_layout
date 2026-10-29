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
  bool _useRtl = false;
  bool _showOcclusions = false;

  @override
  Widget build(BuildContext context) {
    final data = IosWindowControlLayout.of(context);
    final flutterSafeArea = MediaQuery.paddingOf(context);
    final avoidance = _applyWindowControlLayout
        ? data.horizontalAvoidance
        : EdgeInsets.zero;
    final bottomControlPadding = _applyWindowControlLayout
        ? _bottomBoundaryPadding(
            flutterSafeArea: flutterSafeArea,
            verticalSafeArea: data.verticalSafeArea,
            cornerRadii: data.effectiveCornerRadii,
          )
        : EdgeInsets.zero;
    return Directionality(
      textDirection: _useRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Builder(
        builder: (context) => Stack(
          fit: StackFit.expand,
          children: [
            _buildPage(
              context,
              data: data,
              flutterSafeArea: flutterSafeArea,
              avoidance: avoidance,
              bottomControlPadding: bottomControlPadding,
            ),
            if (_showOcclusions)
              Positioned.fill(
                child: _OcclusionDiagnostics(geometry: data.occlusionGeometry),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required IosWindowControlLayoutData data,
    required EdgeInsets flutterSafeArea,
    required EdgeInsets avoidance,
    required EdgeInsets bottomControlPadding,
  }) {
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
                  MenuItemButton(
                    key: const ValueKey('toggle-occlusion-diagnostics'),
                    leadingIcon: const Icon(Icons.crop_free),
                    onPressed: () =>
                        setState(() => _showOcclusions = !_showOcclusions),
                    child: Text(
                      _showOcclusions
                          ? 'Hide occlusion diagnostics'
                          : 'Show occlusion diagnostics',
                    ),
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
            SwitchListTile(
              key: const ValueKey('flutter-rtl-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Use Flutter RTL layout'),
              subtitle: const Text(
                'The reported physical window geometry does not flip',
              ),
              value: _useRtl,
              onChanged: (value) {
                setState(() => _useRtl = value);
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
    EdgeInsets avoidance,
  ) {
    final direction = Directionality.of(context);
    final leadingAvoidance = direction == TextDirection.ltr
        ? avoidance.left
        : avoidance.right;
    final trailingAvoidance = direction == TextDirection.ltr
        ? avoidance.right
        : avoidance.left;
    return AppBar(
      centerTitle: true,
      leadingWidth: kToolbarHeight + _toolbarEdgePadding + leadingAvoidance,
      leading: Padding(
        padding: EdgeInsetsDirectional.only(
          start: _toolbarEdgePadding + leadingAvoidance,
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
            end: _toolbarEdgePadding + trailingAvoidance,
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
    EdgeInsets avoidance,
  ) {
    final direction = Directionality.of(context);
    final startAvoidance = direction == TextDirection.ltr
        ? avoidance.left
        : avoidance.right;
    final endAvoidance = direction == TextDirection.ltr
        ? avoidance.right
        : avoidance.left;
    return CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      padding: EdgeInsetsDirectional.only(
        start: _toolbarEdgePadding + startAvoidance,
        end: _toolbarEdgePadding + endAvoidance,
      ),
      leading: CupertinoButton(
        key: const ValueKey('cupertino-leading'),
        padding: EdgeInsets.zero,
        onPressed: () {},
        child: const Icon(CupertinoIcons.sidebar_left),
      ),
      middle: const Text('Cupertino'),
      trailing: CupertinoButton(
        key: const ValueKey('cupertino-trailing'),
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
  required EdgeInsets verticalSafeArea,
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
  final EdgeInsets insets;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final leftWidth = math.min(insets.left, constraints.maxWidth);
            final rightWidth = math.min(
              insets.right,
              math.max(0.0, constraints.maxWidth - leftWidth),
            );
            return Container(
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: leftWidth, color: color),
                  const Expanded(child: Center(child: Text('safe content'))),
                  Container(width: rightWidth, color: color),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Diagnostic paint only: the example's existing safe areas remain unchanged.
class _OcclusionDiagnostics extends StatelessWidget {
  const _OcclusionDiagnostics({required this.geometry});

  final IosOcclusionGeometry? geometry;

  @override
  Widget build(BuildContext context) {
    final geometry = this.geometry;
    final bar = geometry?.verticalBarLayoutFrame;
    final status = geometry == null
        ? 'Occlusion geometry unavailable'
        : [
            'View bounds: ${geometry.viewBounds}',
            'Active regions: ${geometry.activeOcclusionRegions.length}; '
                'hasVerticalSystemBar: ${geometry.hasVerticalSystemBar}',
            'Recommended bar: ${bar ?? 'unavailable'}',
            if (bar != null)
              'Bar center x: ${bar.center.dx.toStringAsFixed(1)}',
            'Cyan: view; red: occlusion; blue: bar and center',
            'A recommended bar is not an occlusion or Wi-Fi frame',
          ].join('\n');
    return IgnorePointer(
      key: const ValueKey('occlusion-diagnostics-overlay'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            key: const ValueKey('occlusion-regions-paint'),
            painter: _OcclusionPainter(geometry),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(6),
                color: Colors.white.withValues(alpha: 0.88),
                child: Text(
                  status,
                  key: const ValueKey('occlusion-diagnostics-status'),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    inherit: false,
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OcclusionPainter extends CustomPainter {
  const _OcclusionPainter(this.geometry);

  final IosOcclusionGeometry? geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = this.geometry;
    if (geometry == null) return;
    canvas.drawRect(
      geometry.viewBounds.deflate(1),
      Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final bar = geometry.verticalBarLayoutFrame;
    if (bar != null) {
      canvas.drawRect(
        bar,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(bar.center.dx, bar.top),
        Offset(bar.center.dx, bar.bottom),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 1,
      );
    }
    for (final region in geometry.activeOcclusionRegions) {
      canvas.drawRect(
        region,
        Paint()..color = Colors.red.withValues(alpha: 0.25),
      );
      canvas.drawRect(
        region,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_OcclusionPainter oldDelegate) =>
      geometry != oldDelegate.geometry;
}
