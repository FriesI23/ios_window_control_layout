import UIKit

/// Directional insets mirrored by Dart's `DirectionalInsetsPayload`.
struct DirectionalInsetsPayload {
    let start: Double
    let top: Double
    let end: Double
    let bottom: Double

    init(
        start: Double,
        top: Double,
        end: Double,
        bottom: Double
    ) {
        self.start = start
        self.top = top
        self.end = end
        self.bottom = bottom
    }

    init(_ insets: NSDirectionalEdgeInsets) {
        self.init(
            start: Double(insets.leading),
            top: Double(insets.top),
            end: Double(insets.trailing),
            bottom: Double(insets.bottom)
        )
    }

    func encode() -> [String: Double] {
        [
            "start": start,
            "top": top,
            "end": end,
            "bottom": bottom,
        ]
    }
}

/// Physical corner radii mirrored by Dart's `CornerRadiiPayload`.
struct CornerRadiiPayload {
    let topLeft: Double
    let topRight: Double
    let bottomLeft: Double
    let bottomRight: Double

    static let zero = CornerRadiiPayload(
        topLeft: 0,
        topRight: 0,
        bottomLeft: 0,
        bottomRight: 0
    )

    func encode() -> [String: Double] {
        [
            "topLeft": topLeft,
            "topRight": topRight,
            "bottomLeft": bottomLeft,
            "bottomRight": bottomRight,
        ]
    }
}

/// Versioned payload containing only StandardMessageCodec-compatible values.
/// Keep this structure synchronized with Dart's `LayoutPayload`.
struct LayoutPayload {
    static let schemaVersion = 4

    static func layoutRegionsUnavailable(
        isPad: Bool,
        isFullScreen: Bool
    ) -> LayoutPayload {
        LayoutPayload(
            isAvailable: false,
            isPad: isPad,
            isFullScreen: isFullScreen,
            baseMargins: DirectionalInsetsPayload(.zero),
            horizontalMargins: DirectionalInsetsPayload(.zero),
            verticalMargins: DirectionalInsetsPayload(.zero),
            baseSafeArea: DirectionalInsetsPayload(.zero),
            horizontalSafeArea: DirectionalInsetsPayload(.zero),
            verticalSafeArea: DirectionalInsetsPayload(.zero),
            effectiveCornerRadii: .zero
        )
    }

    let isAvailable: Bool
    let isPad: Bool
    let isFullScreen: Bool
    let baseMargins: DirectionalInsetsPayload
    let horizontalMargins: DirectionalInsetsPayload
    let verticalMargins: DirectionalInsetsPayload
    let baseSafeArea: DirectionalInsetsPayload
    let horizontalSafeArea: DirectionalInsetsPayload
    let verticalSafeArea: DirectionalInsetsPayload
    let effectiveCornerRadii: CornerRadiiPayload

    func encode() -> [String: Any] {
        [
            "schemaVersion": Self.schemaVersion,
            "isAvailable": isAvailable,
            "isPad": isPad,
            "isFullScreen": isFullScreen,
            "baseMargins": baseMargins.encode(),
            "horizontalMargins": horizontalMargins.encode(),
            "verticalMargins": verticalMargins.encode(),
            "baseSafeArea": baseSafeArea.encode(),
            "horizontalSafeArea": horizontalSafeArea.encode(),
            "verticalSafeArea": verticalSafeArea.encode(),
            "effectiveCornerRadii": effectiveCornerRadii.encode(),
        ]
    }
}
