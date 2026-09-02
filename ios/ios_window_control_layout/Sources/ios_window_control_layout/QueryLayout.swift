import Flutter
import UIKit

extension IosWindowControlLayoutPlugin {
    func handleQueryLayout(result: FlutterResult) {
        guard let view = registrar?.viewController?.viewIfLoaded else {
            result(
                FlutterError(
                    code: "view_unavailable",
                    message: "The Flutter root view is not available.",
                    details: nil
                )
            )
            return
        }
        guard let windowScene = view.window?.windowScene else {
            result(
                FlutterError(
                    code: "window_scene_unavailable",
                    message: "The Flutter view is not attached to a window scene.",
                    details: nil
                )
            )
            return
        }

        view.layoutIfNeeded()
        let sceneCoordinateSpace: UICoordinateSpace
        if #available(iOS 26.0, *) {
            sceneCoordinateSpace = windowScene.effectiveGeometry.coordinateSpace
        } else {
            sceneCoordinateSpace = windowScene.coordinateSpace
        }
        let screenCoordinateSpace = windowScene.screen.coordinateSpace
        let sceneBoundsInScreen = sceneCoordinateSpace.convert(
            sceneCoordinateSpace.bounds,
            to: screenCoordinateSpace
        )
        let isPad = view.traitCollection.userInterfaceIdiom == .pad
        let isFullScreen = Self.isFullScreen(
            sceneBoundsInScreen: sceneBoundsInScreen,
            screenBounds: screenCoordinateSpace.bounds
        )

        guard #available(iOS 26.0, *) else {
            result(
                LayoutPayload.layoutRegionsUnavailable(
                    isPad: isPad,
                    isFullScreen: isFullScreen
                ).encode()
            )
            return
        }

        let payload = Self.queryLayout(
            isPad: isPad,
            isFullScreen: isFullScreen,
            layoutDirection: view.effectiveUserInterfaceLayoutDirection,
            baseMargins: view.directionalEdgeInsets(for: .margins()),
            horizontalMargins: view.directionalEdgeInsets(
                for: .margins(cornerAdaptation: .horizontal)
            ),
            verticalMargins: view.directionalEdgeInsets(
                for: .margins(cornerAdaptation: .vertical)
            ),
            baseSafeArea: view.directionalEdgeInsets(for: .safeArea()),
            horizontalSafeArea: view.directionalEdgeInsets(
                for: .safeArea(cornerAdaptation: .horizontal)
            ),
            verticalSafeArea: view.directionalEdgeInsets(
                for: .safeArea(cornerAdaptation: .vertical)
            ),
            effectiveCornerRadii: CornerRadiiPayload(
                topLeft: Double(view.effectiveRadius(corner: .topLeft)),
                topRight: Double(view.effectiveRadius(corner: .topRight)),
                bottomLeft: Double(view.effectiveRadius(corner: .bottomLeft)),
                bottomRight: Double(view.effectiveRadius(corner: .bottomRight))
            )
        )
        result(payload.encode())
    }

    /// iPadOS does not expose `UIWindowScene.isFullScreen`; that property is
    /// supported only by Mac Catalyst. A scene is fullscreen when its complete
    /// coordinate-space bounds match the current coordinate space of its
    /// associated screen.
    static func isFullScreen(
        sceneBoundsInScreen: CGRect,
        screenBounds: CGRect
    ) -> Bool {
        sceneBoundsInScreen.standardized.equalTo(screenBounds.standardized)
    }

    static func queryLayout(
        isPad: Bool,
        isFullScreen: Bool,
        layoutDirection: UIUserInterfaceLayoutDirection,
        baseMargins: NSDirectionalEdgeInsets,
        horizontalMargins: NSDirectionalEdgeInsets,
        verticalMargins: NSDirectionalEdgeInsets,
        baseSafeArea: NSDirectionalEdgeInsets,
        horizontalSafeArea: NSDirectionalEdgeInsets,
        verticalSafeArea: NSDirectionalEdgeInsets,
        effectiveCornerRadii: CornerRadiiPayload
    ) -> LayoutPayload {
        LayoutPayload(
            isAvailable: true,
            isPad: isPad,
            isFullScreen: isFullScreen,
            baseMargins: PhysicalInsetsPayload(
                baseMargins,
                layoutDirection: layoutDirection
            ),
            horizontalMargins: PhysicalInsetsPayload(
                horizontalMargins,
                layoutDirection: layoutDirection
            ),
            verticalMargins: PhysicalInsetsPayload(
                verticalMargins,
                layoutDirection: layoutDirection
            ),
            baseSafeArea: PhysicalInsetsPayload(
                baseSafeArea,
                layoutDirection: layoutDirection
            ),
            horizontalSafeArea: PhysicalInsetsPayload(
                horizontalSafeArea,
                layoutDirection: layoutDirection
            ),
            verticalSafeArea: PhysicalInsetsPayload(
                verticalSafeArea,
                layoutDirection: layoutDirection
            ),
            effectiveCornerRadii: effectiveCornerRadii
        )
    }
}
