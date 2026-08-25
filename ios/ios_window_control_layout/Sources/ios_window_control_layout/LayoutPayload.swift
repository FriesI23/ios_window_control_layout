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

/// Versioned payload containing only StandardMessageCodec-compatible values.
/// Keep this structure synchronized with Dart's `LayoutPayload`.
struct LayoutPayload {
    static let schemaVersion = 1

    static let unavailable = LayoutPayload(
        isAvailable: false,
        baseMargins: DirectionalInsetsPayload(.zero),
        horizontalMargins: DirectionalInsetsPayload(.zero),
        verticalMargins: DirectionalInsetsPayload(.zero)
    )

    let isAvailable: Bool
    let baseMargins: DirectionalInsetsPayload
    let horizontalMargins: DirectionalInsetsPayload
    let verticalMargins: DirectionalInsetsPayload

    func encode() -> [String: Any] {
        [
            "schemaVersion": Self.schemaVersion,
            "isAvailable": isAvailable,
            "baseMargins": baseMargins.encode(),
            "horizontalMargins": horizontalMargins.encode(),
            "verticalMargins": verticalMargins.encode(),
        ]
    }
}
