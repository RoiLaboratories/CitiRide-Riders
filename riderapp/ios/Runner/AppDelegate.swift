import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyActFrssaaKA5CUikTsI8_98RukSoPXBTY")
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let shareChannel = FlutterMethodChannel(
        name: "citiride/share",
        binaryMessenger: controller.binaryMessenger
      )

      shareChannel.setMethodCallHandler { call, result in
        guard call.method == "shareImage" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let arguments = call.arguments as? [String: Any],
          let path = arguments["path"] as? String
        else {
          result(FlutterError(code: "missing_path", message: "Screenshot path is missing.", details: nil))
          return
        }

        let text = arguments["text"] as? String ?? ""
        let fileUrl = URL(fileURLWithPath: path)
        var items: [Any] = []

        if !text.isEmpty {
          items.append(text)
        }
        items.append(fileUrl)

        let activityController = UIActivityViewController(
          activityItems: items,
          applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
          popover.sourceView = controller.view
          popover.sourceRect = CGRect(
            x: controller.view.bounds.midX,
            y: controller.view.bounds.midY,
            width: 0,
            height: 0
          )
          popover.permittedArrowDirections = []
        }

        controller.present(activityController, animated: true)
        result(true)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
