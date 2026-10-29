import Flutter
import UIKit

public final class IosWindowControlLayoutPlugin: NSObject, FlutterPlugin {
    private static let channelName = "ios_window_control_layout"
    private static let occlusionChannelName = "ios_window_control_layout/occlusion_changes"

    weak var registrar: FlutterPluginRegistrar?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var occlusionObserver: OcclusionGeometryObserving?
    typealias OcclusionObserverFactory = (UIView, @escaping () -> Void) -> OcclusionGeometryObserving?
    var occlusionObserverFactory: OcclusionObserverFactory = { rootView, onChange in
        guard Thread.isMainThread else { return nil }
        // Flutter's default platform channel and lifecycle callbacks run on
        // the UIKit thread; keep the public plugin protocol nonisolated.
        return MainActor.assumeIsolated {
            guard #available(iOS 27.1, *),
                  let capabilities = ReservedRegionCapabilities.resolve(for: rootView) else { return nil }
            let observer = ReservedRegionObserver(rootView: rootView, capabilities: capabilities, onChange: onChange)
            return observer.isObserving ? observer : nil
        }
    }
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var invalidationPending = false
    private var invalidationSequence = 0
    private var isDetached = false

    public init(registrar: FlutterPluginRegistrar? = nil) {
        self.registrar = registrar
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = IosWindowControlLayoutPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
        let eventChannel = FlutterEventChannel(
            name: occlusionChannelName,
            binaryMessenger: registrar.messenger()
        )
        instance.eventChannel = eventChannel
        eventChannel.setStreamHandler(instance)
        // Flutter only delivers detachFromEngine to a published instance.
        registrar.publish(instance)
        instance.observeRootLifecycle()
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        detachOcclusionObservation()
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        self.registrar = nil
    }

    deinit {
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch Method(rawValue: call.method) {
        case .queryLayout:
            handleQueryLayout(result: result)
        case nil:
            result(FlutterMethodNotImplemented)
        }
    }

    private enum Method: String {
        case queryLayout
    }
}

extension IosWindowControlLayoutPlugin: FlutterStreamHandler {
    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        synchronizeOcclusionObserver(with: registrar?.viewController?.viewIfLoaded)
        scheduleOcclusionInvalidation()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Queries still need the observer's snapshot without an event listener.
        eventSink = nil
        return nil
    }

    func detachOcclusionObservation() {
        // Notify a still-connected Dart listener before unbinding the channel.
        invalidationSequence += 1
        eventSink?(invalidationSequence)
        isDetached = true
        eventSink = nil
        occlusionObserver?.detach()
        occlusionObserver = nil
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
        lifecycleObservers.removeAll()
    }

    var occlusionGeometry: OcclusionGeometryPayload? {
        occlusionObserver?.geometry
    }

    func synchronizeOcclusionObserver(with view: UIView?) {
        guard !isDetached else { return }
        guard #available(iOS 27.1, *), let view, view.window != nil else {
            if occlusionObserver != nil {
                occlusionObserver?.detach()
                occlusionObserver = nil
                scheduleOcclusionInvalidation()
            }
            return
        }
        if occlusionObserver?.rootView === view {
            // A query must remain a read for an unchanged root. Requesting a
            // constraints pass here can make Flutter send metrics again and
            // create a metrics -> query -> native layout feedback loop.
            return
        }
        if occlusionObserver != nil {
            occlusionObserver?.detach()
            occlusionObserver = nil
            scheduleOcclusionInvalidation()
        }
        // Resolve capabilities before attaching a view. A missing capability
        // leaves queries read-only and cannot start an invalidation loop.
        guard let observer = occlusionObserverFactory(view, { [weak self] in
            self?.scheduleOcclusionInvalidation()
        }) else { return }
        occlusionObserver = observer
        scheduleOcclusionInvalidation()
    }

    private func observeRootLifecycle() {
        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIWindow.didBecomeKeyNotification,
            UIWindow.didResignKeyNotification,
            UIScene.didActivateNotification,
            UIScene.didDisconnectNotification,
        ]
        lifecycleObservers = names.map { name in
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.synchronizeOcclusionObserver(
                    with: self.registrar?.viewController?.viewIfLoaded
                )
            }
        }
    }

    private func scheduleOcclusionInvalidation() {
        guard !isDetached, !invalidationPending else { return }
        invalidationPending = true
        // Region reads happen during updateConstraints. Deliver after that pass,
        // combining detach, bounds, trait, and region changes into one signal.
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isDetached else { return }
            self.invalidationPending = false
            self.invalidationSequence += 1
            self.eventSink?(self.invalidationSequence)
        }
    }
}
