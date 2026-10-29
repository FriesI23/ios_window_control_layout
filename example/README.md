# ios_window_control_layout example

Run `flutter run` from this directory.

Use the menu to switch between Material and Cupertino toolbars or enable
**Show occlusion diagnostics**. The other switches compare window-control
avoidance and Flutter RTL layout.

On iOS/iPadOS 27.1+, the diagnostic overlay can display:

| Color | Meaning |
| --- | --- |
| Cyan | Flutter view bounds |
| Red | Active system occlusions |
| Blue | Optional recommended vertical-bar region and its center line |

`Occlusion geometry unavailable` means no usable snapshot is available;
`Active regions: 0` means no active occlusions. The overlay does not change
content layout or Safe Area.

See the [package README](../README.md#occlusion-geometry) for coordinate
conventions and placement guidance.
