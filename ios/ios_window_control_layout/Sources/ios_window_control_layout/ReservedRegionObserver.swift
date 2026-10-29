import Darwin
import ObjectiveC
import UIKit

/// Keep iOS 27.1-only UIKit types out of the plugin's stored properties so the
/// plugin still loads on its existing minimum supported operating system.
protocol OcclusionGeometryObserving: AnyObject {
    var rootView: UIView? { get }
    var geometry: OcclusionGeometryPayload? { get }
    func refresh()
    func detach()
}

/// Optional public bar-layout capability. The factory's scalar arguments are
/// invoked only after checking the exact Objective-C ABI from UIKit's header.
/// Its cached regions are reused so repeated reads do not accumulate guides.
@MainActor
@available(iOS 27.1, *)
struct VerticalBarLayoutCapabilities {
    private static let factorySelector = NSSelectorFromString("layoutRegionForBarOnEdge:extent:")
    private static let guideSelector = NSSelectorFromString("layoutGuideForLayoutRegion:")
    private let leftRegion: NSObject
    private let rightRegion: NSObject
    private typealias Factory =
        @convention(c) (AnyObject, Selector, UInt, CGFloat) -> Unmanaged<AnyObject>?

    static func resolve(
        classLookup: (String) -> NSObject.Type? = { NSClassFromString($0) as? NSObject.Type }
    ) -> VerticalBarLayoutCapabilities? {
        guard let regionType = classLookup("UIViewLayoutRegion"),
            let method = class_getClassMethod(regionType, factorySelector),
            supportsFactorySignature(method)
        else { return nil }
        let factory = unsafeBitCast(method_getImplementation(method), to: Factory.self)
        // 44pt is a minimum interactive-control probe extent, not device or
        // status-icon geometry. UIKit supplies the position of this region.
        guard
            let left = factory(
                regionType as AnyObject, factorySelector, UIRectEdge.left.rawValue, 44)?
                .takeUnretainedValue() as? NSObject,
            let right = factory(
                regionType as AnyObject, factorySelector, UIRectEdge.right.rawValue, 44)?
                .takeUnretainedValue() as? NSObject
        else { return nil }
        return VerticalBarLayoutCapabilities(leftRegion: left, rightRegion: right)
    }

    static func supportsFactorySignature(_ method: Method) -> Bool {
        guard method_getNumberOfArguments(method) == 4 else { return false }
        let result = method_copyReturnType(method)
        defer { free(result) }
        guard let edge = method_copyArgumentType(method, 2) else { return false }
        defer { free(edge) }
        guard let extent = method_copyArgumentType(method, 3) else { return false }
        defer { free(extent) }
        return String(cString: result) == "@" && String(cString: edge) == "Q"
            && String(cString: extent) == "d"
    }

    func read(from view: UIView, rootView: UIView, verticalEdge: Int) -> CGRect? {
        let isLeft: Bool
        switch verticalEdge {
        case 1:  // UIVerticalBarEdgeLeading, resolved in UIKit's native direction.
            isLeft = view.effectiveUserInterfaceLayoutDirection == .leftToRight
        case 2:  // UIVerticalBarEdgeTrailing.
            isLeft = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        default:
            return nil
        }
        guard view.responds(to: Self.guideSelector),
            let guide = view.perform(Self.guideSelector, with: isLeft ? leftRegion : rightRegion)?
                .takeUnretainedValue() as? UILayoutGuide,
            guide.owningView === view
        else { return nil }
        let frame = view.convert(guide.layoutFrame, to: rootView)
        guard frame.origin.x.isFinite, frame.origin.y.isFinite,
            frame.width.isFinite, frame.height.isFinite,
            frame.maxX.isFinite, frame.maxY.isFinite, !frame.isEmpty,
            frame.midX >= rootView.bounds.minX, frame.midX <= rootView.bounds.maxX
        else { return nil }
        return frame
    }
}

/// Resolves public UIKit entry points without requiring their declarations in
/// the build SDK. Missing or malformed capability data is always unavailable.
@MainActor
@available(iOS 27.1, *)
struct ReservedRegionCapabilities {
    private static let querySelector = NSSelectorFromString("reservedRegionsOfKind:")
    private static let edgeSelector = NSSelectorFromString("verticalBarEdge")
    private static let registrationSelector = NSSelectorFromString(
        "registerForTraitChanges:withHandler:")
    private static let unregistrationSelector = NSSelectorFromString("unregisterForTraitChanges:")
    private let occlusionKind: NSObject
    private let verticalBarTraits: NSArray
    private let verticalBarLayout: VerticalBarLayoutCapabilities?
    typealias TraitChangeHandler = @convention(block) (AnyObject, UITraitCollection) -> Void
    var hasTraitObservers: Bool { verticalBarTraits.count > 0 }

    static func resolve(
        for view: UIView,
        classLookup: (String) -> NSObject.Type? = { NSClassFromString($0) as? NSObject.Type }
    ) -> ReservedRegionCapabilities? {
        let kindSelector = NSSelectorFromString("occlusionRegionKind")
        let traitsSelector = NSSelectorFromString("systemTraitsAffectingVerticalBarEdge")
        guard let kindType = classLookup("UIViewReservedRegionKind"),
            kindType.responds(to: kindSelector),
            let kind = kindType.perform(kindSelector)?.takeUnretainedValue() as? NSObject,
            view.responds(to: querySelector),
            UITraitCollection.responds(to: traitsSelector),
            let traits = UITraitCollection.perform(traitsSelector)?.takeUnretainedValue()
                as? NSArray,
            traits.allSatisfy({ object_isClass($0 as AnyObject) }),
            view.responds(to: registrationSelector),
            view.responds(to: unregistrationSelector),
            view.traitCollection.responds(to: edgeSelector)
        else { return nil }
        return ReservedRegionCapabilities(
            occlusionKind: kind,
            verticalBarTraits: traits,
            verticalBarLayout: VerticalBarLayoutCapabilities.resolve(classLookup: classLookup)
        )
    }

    func register(on view: UIView, handler: @escaping TraitChangeHandler) -> NSObject? {
        guard view.responds(to: Self.registrationSelector) else { return nil }
        // The Objective-C API consumes Class objects. Swift's UITrait facade
        // uses value-type definitions and is not a valid cast for this NSArray.
        return view.perform(Self.registrationSelector, with: verticalBarTraits, with: handler)?
            .takeUnretainedValue() as? NSObject
    }

    static func unregister(_ registration: NSObject, from view: UIView) {
        guard view.responds(to: unregistrationSelector) else { return }
        _ = view.perform(unregistrationSelector, with: registration)
    }

    func read(from view: UIView, rootView: UIView) -> OcclusionGeometryPayload? {
        guard Self.isValid(rootView.bounds), !rootView.bounds.isEmpty,
            view.responds(to: Self.querySelector),
            let regions = view.perform(Self.querySelector, with: occlusionKind)?
                .takeUnretainedValue()
                as? [NSObject],
            view.traitCollection.responds(to: Self.edgeSelector),
            let edge = view.traitCollection.value(forKey: "verticalBarEdge") as? NSNumber,
            edge.doubleValue.isFinite
        else { return nil }
        var frames: [CGRect] = []
        for region in regions {
            guard region.responds(to: NSSelectorFromString("isActive")),
                region.responds(to: NSSelectorFromString("frame")),
                let active = region.value(forKey: "active") as? NSNumber,
                let frame = region.value(forKey: "frame") as? NSValue,
                String(cString: frame.objCType) == String(cString: NSValue(cgRect: .zero).objCType),
                Self.isValid(frame.cgRectValue)
            else { return nil }
            if active.boolValue {
                let converted = view.convert(frame.cgRectValue, to: rootView)
                guard Self.isValid(converted) else { return nil }
                frames.append(converted)
            }
        }
        return OcclusionGeometryPayload(
            viewBounds: rootView.bounds,
            activeOcclusionRegions: frames,
            hasVerticalSystemBar: edge.intValue != 0,
            verticalBarLayoutFrame: verticalBarLayout?.read(
                from: view, rootView: rootView, verticalEdge: edge.intValue)
        )
    }

    func verticalBarLayoutFrame(from view: UIView, rootView: UIView) -> CGRect? {
        guard view.traitCollection.responds(to: Self.edgeSelector),
            let edge = view.traitCollection.value(forKey: "verticalBarEdge") as? NSNumber
        else { return nil }
        return verticalBarLayout?.read(from: view, rootView: rootView, verticalEdge: edge.intValue)
    }

    private static func isValid(_ rect: CGRect) -> Bool {
        rect.origin.x.isFinite && rect.origin.y.isFinite && rect.width.isFinite
            && rect.height.isFinite
            && rect.width >= 0 && rect.height >= 0
    }
}

@available(iOS 27.1, *)
final class ReservedRegionObserver: UIView, OcclusionGeometryObserving {
    typealias GeometryReader = (UIView, UIView) -> OcclusionGeometryPayload?

    private(set) weak var rootView: UIView?
    private(set) var geometry: OcclusionGeometryPayload?
    private var onChange: (() -> Void)?
    private var geometryReader: GeometryReader?
    private var barFrameReader: ((UIView, UIView) -> CGRect?)?
    private var lastAttemptBounds: CGRect?
    private var traitRegistration: NSObject?
    private(set) var isObserving = false

    init(
        rootView: UIView,
        geometryReader: GeometryReader? = nil,
        capabilities: ReservedRegionCapabilities? = nil,
        onChange: @escaping () -> Void
    ) {
        self.rootView = rootView
        let capabilities = capabilities ?? ReservedRegionCapabilities.resolve(for: rootView)
        self.geometryReader =
            geometryReader
            ?? capabilities.map { capabilities in
                { view, rootView in capabilities.read(from: view, rootView: rootView) }
            }
        if geometryReader == nil, let capabilities {
            barFrameReader = { view, rootView in
                capabilities.verticalBarLayoutFrame(from: view, rootView: rootView)
            }
        }
        self.onChange = onChange
        super.init(frame: rootView.bounds)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        isOpaque = false
        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let capabilities, capabilities.hasTraitObservers {
            guard
                let registration = capabilities.register(
                    on: self,
                    handler: { environment, _ in
                        (environment as? UIView)?.setNeedsUpdateConstraints()
                    })
            else {
                self.geometryReader = nil
                return
            }
            traitRegistration = registration
        }
        guard self.geometryReader != nil else { return }
        isObserving = true
        rootView.addSubview(self)
        setNeedsUpdateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var requiresConstraintBasedLayout: Bool { true }

    override func updateConstraints() {
        if let rootView, superview === rootView, window != nil,
            rootView.window === window, frame == rootView.bounds
        {
            // A failed read still counts as an attempt at these bounds.
            // Repeated layout must not poll or dirty the Flutter root again.
            lastAttemptBounds = rootView.bounds
            // UIKit tracks this public query during updateConstraints and
            // schedules another pass for region changes without Flutter metrics.
            replaceGeometry(geometryReader?(self, rootView))
        } else {
            lastAttemptBounds = nil
            replaceGeometry(nil)
        }
        // UIKit requires super last and forbids scheduling another constraints
        // pass here. Changes are coalesced by the plugin after this pass.
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let rootView, lastAttemptBounds != rootView.bounds {
            refresh()
        } else if let rootView, var snapshot = geometry,
            let barFrameReader, superview === rootView, window != nil
        {
            // Layout guides can finish positioning after updateConstraints.
            // Refresh only this optional field from the same cached guides;
            // native occlusion tracking remains in updateConstraints.
            snapshot.verticalBarLayoutFrame = barFrameReader(self, rootView)
            replaceGeometry(snapshot)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            lastAttemptBounds = nil
            replaceGeometry(nil)
        } else {
            refresh()
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview !== rootView {
            lastAttemptBounds = nil
            replaceGeometry(nil)
        }
    }

    func refresh() {
        guard let rootView, superview === rootView, window != nil else {
            replaceGeometry(nil)
            return
        }
        // Match the complete Flutter view, including regions outside SafeArea.
        // The observer owns no content, constraints, safe-area or hit-test space.
        let frameChanged = frame != rootView.bounds
        let snapshotBoundsChanged = lastAttemptBounds != rootView.bounds
        if frameChanged || snapshotBoundsChanged {
            replaceGeometry(nil)
        }
        if frameChanged {
            frame = rootView.bounds
        }
        if frameChanged || snapshotBoundsChanged {
            setNeedsUpdateConstraints()
        }
    }

    func detach() {
        isObserving = false
        if let traitRegistration {
            ReservedRegionCapabilities.unregister(traitRegistration, from: self)
            self.traitRegistration = nil
        }
        lastAttemptBounds = nil
        replaceGeometry(nil)
        onChange = nil
        rootView = nil
        removeFromSuperview()
    }

    private func replaceGeometry(_ next: OcclusionGeometryPayload?) {
        guard geometry != next else { return }
        geometry = next
        onChange?()
    }
}
