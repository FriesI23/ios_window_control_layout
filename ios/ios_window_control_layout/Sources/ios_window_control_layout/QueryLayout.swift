import Flutter
import UIKit

extension IosWindowControlLayoutPlugin {
    func handleQueryLayout(result: FlutterResult) {
        guard #available(iOS 26.0, *) else {
            result(LayoutPayload.unavailable.encode())
            return
        }
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

        view.layoutIfNeeded()
        let payload = Self.queryLayout(
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

    static func queryLayout(
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
            baseMargins: DirectionalInsetsPayload(baseMargins),
            horizontalMargins: DirectionalInsetsPayload(horizontalMargins),
            verticalMargins: DirectionalInsetsPayload(verticalMargins),
            baseSafeArea: DirectionalInsetsPayload(baseSafeArea),
            horizontalSafeArea: DirectionalInsetsPayload(horizontalSafeArea),
            verticalSafeArea: DirectionalInsetsPayload(verticalSafeArea),
            effectiveCornerRadii: effectiveCornerRadii
        )
    }
}
