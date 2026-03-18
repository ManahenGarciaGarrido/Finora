import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Configurar Method Channel para información de versión de iOS
    let controller = window?.rootViewController as! FlutterViewController
    let platformVersionChannel = FlutterMethodChannel(
      name: "com.finora.app/platform_version",
      binaryMessenger: controller.binaryMessenger
    )

    platformVersionChannel.setMethodCallHandler { [weak self] (call, result) in
      guard self != nil else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
        return
      }

      switch call.method {
      case "getIOSVersion":
        // Retorna la versión de iOS (e.g., "13.0")
        let systemVersion = UIDevice.current.systemVersion
        result(systemVersion)

      case "getIOSVersionNumber":
        // Retorna la versión como número (e.g., 13.0)
        if let version = Double(UIDevice.current.systemVersion.components(separatedBy: ".").prefix(2).joined(separator: ".")) {
          result(version)
        } else {
          result(FlutterError(code: "PARSE_ERROR", message: "Unable to parse iOS version", details: nil))
        }

      case "getDeviceInfo":
        // Retorna información completa del dispositivo
        let device = UIDevice.current
        let deviceInfo: [String: Any] = [
          "systemName": device.systemName,
          "systemVersion": device.systemVersion,
          "model": device.model,
          "name": device.name,
          "identifierForVendor": device.identifierForVendor?.uuidString ?? "unknown",
          "isIPhone": device.userInterfaceIdiom == .phone,
          "isIPad": device.userInterfaceIdiom == .pad
        ]
        result(deviceInfo)

      case "isAtLeastVersion":
        // Verifica si el dispositivo tiene al menos cierta versión
        guard let args = call.arguments as? [String: Any],
              let requiredVersion = args["version"] as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Version argument is required", details: nil))
          return
        }

        if let currentVersion = Double(UIDevice.current.systemVersion.components(separatedBy: ".").prefix(2).joined(separator: ".")) {
          result(currentVersion >= requiredVersion)
        } else {
          result(false)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
