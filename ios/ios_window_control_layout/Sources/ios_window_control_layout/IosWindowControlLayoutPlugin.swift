import Flutter
import UIKit

public final class IosWindowControlLayoutPlugin: NSObject, FlutterPlugin {
    private static let channelName = "ios_window_control_layout"

    weak var registrar: FlutterPluginRegistrar?

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
