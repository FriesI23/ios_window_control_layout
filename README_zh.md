# ios_window_control_layout

![Package][pubdev-package]
![Likes][pubdev-likes]
![Popularity][pubdev-popularity]
![Points][pubdev-points]

[EN](README.md) / 中文

> **让 Flutter 内容避开 iPadOS 窗口控制按钮** — 使用 UIKit 提供的
> corner-adapted layout margins，同时由应用自行决定 AppBar、侧边栏和
> padding 的具体布局。

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
| iOS/iPadOS 26+ | 从当前 Flutter view 查询 `UIView.LayoutRegion`。 |
| 更早的 iOS 版本 | 返回 `IosWindowControlLayoutData.zero`。 |
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
```

`of` 和 `maybeOf` 会建立 inherited dependency；`read` 和 `maybeRead`
只读取当前值。首次 frame 完成后、窗口尺寸变化以及应用恢复时，布局会自动刷新。
也可以主动请求刷新：

```dart
await IosWindowControlLayout.refresh(context);
```

如果只需要一次查询，无需将 widget 加入 tree：

```dart
final layout = await IosWindowControlLayout.query();
```

Avoidance 表示需要额外增加的空间，不会替代组件原有的 padding。应保留组件的
常规 padding，再叠加 avoidance，如下面的完整示例所示。

<details>
<summary>完整示例</summary>

```dart
import 'package:flutter/material.dart';
import 'package:ios_window_control_layout/ios_window_control_layout.dart';

const _edgePadding = 16.0;

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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: kToolbarHeight + _edgePadding + avoidance.start,
        leading: Padding(
          padding: EdgeInsetsDirectional.only(
            start: _edgePadding + avoidance.start,
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
              end: _edgePadding + avoidance.end,
            ),
            child: IconButton(
              onPressed: () => IosWindowControlLayout.refresh(context),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsetsDirectional.only(
          start: _edgePadding + avoidance.start,
          end: _edgePadding + avoidance.end,
        ),
        child: Center(
          child: Text('Available: ${layout.isAvailable}'),
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
[pubdev-popularity]: https://img.shields.io/pub/popularity/ios_window_control_layout?logo=dart
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
