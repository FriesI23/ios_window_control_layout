# ios_window_control_layout

![Package][pubdev-package]
![Likes][pubdev-likes]
![Points][pubdev-points]

[EN](README.md) / 中文

> **让 Flutter 内容避开 iPadOS 窗口控制按钮** — 使用 UIKit 提供的
> corner-adapted margins 与 safe areas，同时由应用自行决定 AppBar、
> 浮动控件、侧边栏和 padding 的具体布局。

## 截图

### Cupertino

![Cupertino 应用窗口控制布局前后对比](screenshots/cupertino-before-after.png)

<details>
<summary>Material</summary>

![Material 应用窗口控制布局前后对比](screenshots/material-before-after.png)

</details>

## 平台支持

| 平台 | 行为 |
| --- | --- |
| iOS/iPadOS 27.1+ | 可用时额外提供活动系统遮挡区域。 |
| iOS/iPadOS 26+ | 从当前 Flutter view 查询 `UIView.LayoutRegion`。 |
| 更早的 iOS 版本 | 保留设备和窗口状态，不可用的布局区域为零，遮挡几何为 `null`。 |
| 其他平台 | 不调用平台通道，直接返回 `IosWindowControlLayoutData.zero`。 |

## 快速开始

```shell
flutter pub add ios_window_control_layout
```

## 使用

```dart
import 'package:ios_window_control_layout/ios_window_control_layout.dart';
```

包装需要随窗口布局变化更新的 widget tree：

```dart
IosWindowControlLayout(
  child: MaterialApp(home: MyHomePage()),
);
```

在 `build` 中读取当前布局：

```dart
final layout = IosWindowControlLayout.of(context);
final toolbarInsets = layout.horizontalAvoidance;
final floatingControlInsets = layout.horizontalSafeArea;
final windowCorners = layout.effectiveCornerRadii;
```

所有 inset 属性都是物理 `EdgeInsets`。其中 `left` 和 `right` 描述 UIKit
窗口的实际几何位置，不会在 Flutter `Directionality` 改变时翻转。将其分配给
逻辑 leading 或 trailing 控件时，需要显式选择对应的物理侧。

`of` 和 `maybeOf` 会建立 inherited dependency；`read` 和 `maybeRead`
只读取当前值。首次 frame 完成后、窗口尺寸或原生遮挡变化以及应用恢复时，布局会自动刷新。
也可以主动请求刷新：

```dart
await IosWindowControlLayout.refresh(context);
```

如果只需要一次查询，无需将 widget 加入 tree：

```dart
final layout = await IosWindowControlLayout.query();
```

### 布局属性

| 属性 | 用途 |
| --- | --- |
| `isAvailable` | 判断当前窗口是否能提供 iOS 26 的布局参考；为 `false` 时继续使用应用原有布局即可。 |
| `isPad` | 判断当前 Flutter view 是否使用 UIKit 的 iPad interface idiom。 |
| `isFullScreen` | 通过 scene 与 screen 坐标空间是否完整重合，判断当前 iPadOS scene 是否全屏；不使用尺寸阈值。 |
| `hasWindowControlAvoidance` | 判断当前窗口化 iPad 是否存在用于窗口控制按钮的额外水平避让。 |
| `baseMargins` | UIKit 常规的内容边距，代表不考虑特殊圆角时的标准内容区。 |
| `horizontalMargins` | 已照顾左右圆角的内容区，适合 AppBar 两侧操作、导航控件、侧边栏和靠窗口两侧对齐的内容。 |
| `verticalMargins` | 已照顾上下圆角的内容区，适合靠近窗口顶部或底部排布的内容。 |
| `baseSafeArea` | UIKit 常规的安全区，适合在 Flutter 内容需要与周边 iOS 界面保持一致时作为原生参考。 |
| `horizontalSafeArea` | 适合放置在左右两侧的浮动操作，例如悬浮按钮、边缘工具条或窗口侧边的快捷控件。 |
| `verticalSafeArea` | 适合放置在顶部或底部的浮动控件，例如浮动底栏、工具栏或 dock。 |
| `effectiveCornerRadii` | 当前窗口四个物理圆角的实际弧度，适合让卡片、浮动控件或自定义形状只跟随邻近的圆角。 |
| `horizontalAvoidance` | 左右圆角额外需要让出的空间，可直接叠加到 AppBar、侧边栏或已有的水平 padding 上。 |
| `verticalAvoidance` | 上下圆角额外需要让出的空间，适合在常规内容边距已经存在时叠加使用。 |
| `horizontalSafeAreaAvoidance` | 左右两侧额外需要的安全距离，适合已经放在 Flutter 常规安全区内的浮动控件。 |
| `verticalSafeAreaAvoidance` | 顶部或底部额外需要的安全距离，适合已经由 `SafeArea` 保护的顶部或底部控件。 |
| `hasAvoidance` | 快速判断当前窗口的圆角是否让常规内容区产生了额外留白。 |

Margin 类数值更适合普通内容，safe-area 类数值更适合靠近设备或
窗口圆角的浮动可交互控件。完整区域值可以直接作为布局参考；
`Avoidance` 值只表示在原有布局上需要再增加的部分。Inset 仍然描述的是
矩形根 view；如果控件只需要跟随邻近的物理圆角，使用
`effectiveCornerRadii` 会更合适。

所有数值都属于同一份不可变布局快照，并会一起刷新。iOS 26 以下仍会
返回当前 view 的 `isPad` 与 scene 的 `isFullScreen`，不可用的布局区域和
圆角数值为零；其他平台返回完整的零值快照。

### 遮挡几何

在 iOS/iPadOS 27.1+ 上，`occlusionGeometry` 可提供当前活动的系统遮挡区域：

```dart
final geometry = IosWindowControlLayout.of(context).occlusionGeometry;
```

| 属性 | 用途 |
| --- | --- |
| `viewBounds` | 当前 Flutter view 的边界。 |
| `activeOcclusionRegions` | 需要避让的活动系统区域。 |
| `hasVerticalSystemBar` | UIKit 的竖向系统栏偏好，不代表栏当前可见。 |
| `verticalBarLayoutFrame` | 可选的控件对齐参考区域，不是额外遮挡。 |

矩形使用 Flutter view 的逻辑坐标与物理方向，不随 RTL 镜像。区域可能越出 view；
使用时先转换到控件局部坐标，再与完整交互区域判断交集。

`null` 表示没有可用几何；非 `null` 且区域列表为空表示没有活动遮挡。
这与描述布局区域能力的 `isAvailable` 相互独立。

使用时仍应保留原有 Safe Area 保护。诊断层的使用方式见[示例说明](example/README.md)。

### 从 0.4.x 迁移

0.5.0 将所有公开的 `EdgeInsetsDirectional` 布局值替换为物理
`EdgeInsets`。直接用作物理 padding 时，将 `.start`/`.end` 改成
`.left`/`.right`。用于 AppBar 的逻辑槽位时，根据 Flutter 当前文字方向映射
物理两侧：

```dart
final avoidance = layout.horizontalAvoidance;
final direction = Directionality.of(context);
final leadingAvoidance = direction == TextDirection.ltr
    ? avoidance.left
    : avoidance.right;
final trailingAvoidance = direction == TextDirection.ltr
    ? avoidance.right
    : avoidance.left;
```

<details>
<summary>完整示例</summary>

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';

const _edgePadding = 16.0;
const _bottomControlMargin = 12.0;

double _horizontalInsetAt(Radius radius, double distanceFromBottom) {
  if (radius.x <= 0 || radius.y <= 0 || distanceFromBottom >= radius.y) {
    return 0;
  }
  final normalizedY = (radius.y - distanceFromBottom) / radius.y;
  return radius.x *
      (1 - math.sqrt(math.max(0, 1 - normalizedY * normalizedY)));
}

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
    final avoidance = layout.horizontalAvoidance;
    final direction = Directionality.of(context);
    final leadingAvoidance = direction == TextDirection.ltr
        ? avoidance.left
        : avoidance.right;
    final trailingAvoidance = direction == TextDirection.ltr
        ? avoidance.right
        : avoidance.left;
    final flutterSafeArea = MediaQuery.viewPaddingOf(context);
    final adaptedBottom = math.max(
      flutterSafeArea.bottom,
      layout.verticalSafeArea.bottom,
    );
    final cornerDistance = adaptedBottom + _bottomControlMargin;
    final bottomPadding = EdgeInsets.only(
      left: math.max(
        0,
        _horizontalInsetAt(layout.effectiveCornerRadii.bottomLeft, cornerDistance) -
            _bottomControlMargin,
      ),
      right: math.max(
        0,
        _horizontalInsetAt(layout.effectiveCornerRadii.bottomRight, cornerDistance) -
            _bottomControlMargin,
      ),
      bottom: math.max(0, adaptedBottom - flutterSafeArea.bottom),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: kToolbarHeight + _edgePadding + leadingAvoidance,
        leading: Padding(
          padding: EdgeInsetsDirectional.only(
            start: _edgePadding + leadingAvoidance,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
          ),
        ),
        title: const Text('Window control layout'),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: _edgePadding + trailingAvoidance,
            ),
            child: IconButton(
              onPressed: () => IosWindowControlLayout.refresh(context),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: _edgePadding + avoidance.left,
          right: _edgePadding + avoidance.right,
        ),
        child: Center(
          child: Text('Available: ${layout.isAvailable}'),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: bottomPadding,
          child: const Card(
            margin: EdgeInsets.all(_bottomControlMargin),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Floating controls'),
            ),
          ),
        ),
      ),
    );
  }
}
```

</details>

示例应用演示了 Material 与 Cupertino AppBar 的手动集成，并有意将控件放在
toolbar 两侧。窗口控制布局开关默认开启；关闭后可以查看未经处理的布局，也可以
在调整 iPad 窗口尺寸时切换 renderer 进行比较。

## 开发

运行完整的非设备检查：

```shell
make check
```

运行 `make help` 查看所有可用的开发命令。

## 贡献

欢迎提交 issue 和 pull request。提交修改前请运行 `make check`。

## 捐赠

[!["Buy Me A Coffee"][buymeacoffee-badge]](https://www.buymeacoffee.com/d49cb87qgww)
[![Alipay][alipay-badge]][alipay-addr]
[![WechatPay][wechat-badge]][wechat-addr]

[![ETH][eth-badge]][eth-addr]
[![BTC][btc-badge]][btc-addr]

## 许可证

本项目基于 MIT License 许可。详见 [LICENSE](./LICENSE)。

```text
MIT License

Copyright (c) 2026 Fries_I23

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

[pubdev-package]: https://img.shields.io/pub/v/ios_window_control_layout.svg
[pubdev-likes]: https://img.shields.io/pub/likes/ios_window_control_layout?logo=dart
[pubdev-points]: https://img.shields.io/pub/points/ios_window_control_layout?logo=dart
[buymeacoffee-badge]: https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black
[alipay-badge]: https://img.shields.io/badge/alipay-00A1E9?style=for-the-badge&logo=alipay&logoColor=white
[alipay-addr]: https://raw.githubusercontent.com/FriesI23/mhabit/main/docs/README/images/donate-alipay.jpg
[wechat-badge]: https://img.shields.io/badge/WeChat-07C160?style=for-the-badge&logo=wechat&logoColor=white
[wechat-addr]: https://raw.githubusercontent.com/FriesI23/mhabit/main/docs/README/images/donate-wechatpay.png
[eth-badge]: https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=Ethereum&logoColor=white
[eth-addr]: https://etherscan.io/address/0x35FC877Ef0234FbeABc51ad7fC64D9c1bE161f8F
[btc-badge]: https://img.shields.io/badge/Bitcoin-000000?style=for-the-badge&logo=bitcoin&logoColor=white
[btc-addr]: https://blockchair.com/bitcoin/address/bc1qz2vjews2fcscmvmcm5ctv47mj6236x9p26zk49
