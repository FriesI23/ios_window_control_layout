import UIKit

/// Physical insets mirrored by Dart's `PhysicalInsetsPayload`.
struct PhysicalInsetsPayload {
    let left: Double
    let top: Double
    let right: Double
    let bottom: Double

    static let zero = PhysicalInsetsPayload(
        left: 0,
        top: 0,
        right: 0,
        bottom: 0
    )

    init(
        left: Double,
        top: Double,
        right: Double,
        bottom: Double
    ) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }

    init(
        _ insets: NSDirectionalEdgeInsets,
        layoutDirection: UIUserInterfaceLayoutDirection
    ) {
        let left =
            switch layoutDirection {
            case .leftToRight:
                insets.leading
            case .rightToLeft:
                insets.trailing
            @unknown default:
                insets.leading
            }
        let right =
            switch layoutDirection {
            case .leftToRight:
                insets.trailing
            case .rightToLeft:
                insets.leading
            @unknown default:
                insets.trailing
            }
        self.init(
            left: Double(left),
            top: Double(insets.top),
            right: Double(right),
            bottom: Double(insets.bottom)
        )
    }

    func encode() -> [String: Double] {
        [
            "left": left,
            "top": top,
            "right": right,
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
    static let schemaVersion = 6

    static func layoutRegionsUnavailable(
        isPad: Bool,
        isFullScreen: Bool
    ) -> LayoutPayload {
        LayoutPayload(
            isAvailable: false,
            isPad: isPad,
            isFullScreen: isFullScreen,
            baseMargins: .zero,
            horizontalMargins: .zero,
            verticalMargins: .zero,
            baseSafeArea: .zero,
            horizontalSafeArea: .zero,
            verticalSafeArea: .zero,
            effectiveCornerRadii: .zero
        )
    }

    let isAvailable: Bool
    let isPad: Bool
    let isFullScreen: Bool
    let baseMargins: PhysicalInsetsPayload
    let horizontalMargins: PhysicalInsetsPayload
    let verticalMargins: PhysicalInsetsPayload
    let baseSafeArea: PhysicalInsetsPayload
    let horizontalSafeArea: PhysicalInsetsPayload
    let verticalSafeArea: PhysicalInsetsPayload
    let effectiveCornerRadii: CornerRadiiPayload
    var occlusionGeometry: OcclusionGeometryPayload? = nil

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
            "occlusionGeometry": occlusionGeometry?.encode() ?? NSNull(),
        ]
    }
}

/// Reserved-region frames are physical Flutter root-view coordinates. UIKit
/// already includes interactive margins in each frame; never add them again.
struct OcclusionGeometryPayload: Equatable {
    let viewBounds: CGRect
    let activeOcclusionRegions: [CGRect]
    let hasVerticalSystemBar: Bool
    var verticalBarLayoutFrame: CGRect? = nil

    func encode() -> [String: Any] {
        [
            "viewBounds": Self.encodeRect(viewBounds),
            "activeOcclusionRegions": activeOcclusionRegions.map(Self.encodeRect),
            "hasVerticalSystemBar": hasVerticalSystemBar,
            "verticalBarLayoutFrame": verticalBarLayoutFrame.map(Self.encodeRect) ?? NSNull(),
        ]
    }

    private static func encodeRect(_ rect: CGRect) -> [String: Double] {
        [
            "x": Double(rect.origin.x),
            "y": Double(rect.origin.y),
            "width": Double(rect.size.width),
            "height": Double(rect.size.height),
        ]
    }
}
