# ios_window_control_layout

Expose UIKit's corner-adapted layout margins to Flutter. The package is aimed
at iPadOS windowed apps whose content can extend underneath system window
controls.

It provides layout data and change notifications only. Your application keeps
ownership of AppBar, NavigationRail, sidebar, and padding decisions.

## Platform support

| Platform | Behavior |
| --- | --- |
| iOS/iPadOS 26+ | Queries `UIView.LayoutRegion` from the current Flutter view. |
| Earlier iOS versions | Returns `IosWindowControlLayoutData.zero`. |
| Other platforms | Returns `IosWindowControlLayoutData.zero` without invoking a channel. |

The plugin does not identify device models or estimate physical screen sizes.
UIKit points map directly to Flutter logical pixels.

## Usage

Import the package through its single public library:

```dart
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
```

Wrap the part of the widget tree that needs live updates:

```dart
IosWindowControlLayout(
  child: MaterialApp(home: MyHomePage()),
);
```

Read the current snapshot during build:

```dart
final layout = IosWindowControlLayout.of(context);
final toolbarInsets = layout.horizontalAvoidance;
```

`of` and `maybeOf` establish an inherited dependency. `read` and `maybeRead`
perform a non-listening lookup. The layout refreshes after its first frame, on
window metric changes, and when the application resumes. An application can
also request a refresh explicitly:

```dart
await IosWindowControlLayout.refresh(context);
```

For one-off access without adding the widget to the tree:

```dart
final layout = await IosWindowControlLayout.query();
```

<details>
<summary>Complete example</summary>

```dart
import 'package:flutter/material.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const IosWindowControlLayout(
      child: MaterialApp(home: ExamplePage()),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = IosWindowControlLayout.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Window control layout')),
      body: Padding(
        padding: layout.horizontalAvoidance,
        child: Center(
          child: Text('Available: ${layout.isAvailable}'),
        ),
      ),
    );
  }
}
```

</details>

## Layout data

`IosWindowControlLayoutData` exposes UIKit's ordinary margins and the margins
adapted along the horizontal and vertical axes. Its convenience getters return
only the non-negative difference from the ordinary margins:

- `horizontalAvoidance`
- `verticalAvoidance`
- `hasAvoidance`

All values use `EdgeInsetsDirectional`, so callers can apply logical leading
and trailing behavior without platform-specific RTL branches.

See the example app for manual Material and Cupertino AppBar integration. The
example deliberately places controls at both toolbar edges and lets you switch
renderer while resizing an iPad window.

## Development

Run the complete non-device check suite:

```shell
make check
```

Run `make help` to list formatting, Markdown lint, package validation, iOS
XCTest, and integration-test entrypoints. Device-backed targets accept
`DEVICE=<simulator-id>`.

## Apple dependency managers

The plugin keeps one Swift source tree under
`ios/ios_window_control_layout/Sources`. `Package.swift` is the primary package
definition, and the podspec points to the same sources for CocoaPods consumers.

The runtime deployment target is iOS 13. Building the iOS 26 layout-region
implementation requires an SDK that contains `UIView.LayoutRegion`; calls are
guarded with an iOS 26 availability check.
