import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';

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

  @override
  Widget build(BuildContext context) {
    final data = IosWindowControlLayout.of(context);
    return Scaffold(
      appBar: switch (_style) {
        _AppBarStyle.material => _buildMaterialAppBar(context, data),
        _AppBarStyle.cupertino => _buildCupertinoAppBar(context, data),
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
            const SizedBox(height: 24),
            Text(
              data.isAvailable
                  ? 'UIKit layout regions available'
                  : 'UIKit layout regions unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Horizontal avoidance: ${data.horizontalAvoidance}'),
            Text('Vertical avoidance: ${data.verticalAvoidance}'),
            const SizedBox(height: 24),
            _InsetsPreview(
              title: 'Horizontal avoidance preview',
              insets: data.horizontalAvoidance,
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
              'that both remain outside the system window controls.',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMaterialAppBar(
    BuildContext context,
    IosWindowControlLayoutData data,
  ) {
    return _HorizontalAvoidanceAppBar(
      avoidance: data.horizontalAvoidance,
      child: AppBar(
        leading: IconButton(
          key: const ValueKey('material-leading'),
          tooltip: 'Leading test button',
          onPressed: () {},
          icon: const Icon(Icons.menu),
        ),
        title: const Text('Material'),
        actions: [
          IconButton(
            tooltip: 'Refresh layout',
            onPressed: () => unawaited(IosWindowControlLayout.refresh(context)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCupertinoAppBar(
    BuildContext context,
    IosWindowControlLayoutData data,
  ) {
    final avoidance = data.horizontalAvoidance;
    return CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      padding: EdgeInsetsDirectional.only(
        start: 16 + avoidance.start,
        end: 16 + avoidance.end,
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

class _HorizontalAvoidanceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _HorizontalAvoidanceAppBar({
    required this.avoidance,
    required this.child,
  });

  final EdgeInsetsDirectional avoidance;
  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final resolved = avoidance.resolve(Directionality.of(context));
    final padding = mediaQuery.padding;
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: EdgeInsets.fromLTRB(
          padding.left + resolved.left,
          padding.top,
          padding.right + resolved.right,
          padding.bottom,
        ),
      ),
      child: child,
    );
  }
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
