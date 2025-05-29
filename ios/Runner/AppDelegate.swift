import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let memoryChannel = FlutterMethodChannel(name: "com.example.benchmark/memory",
                                           binaryMessenger: controller.binaryMessenger)
    
    memoryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      if call.method == "getTotalMemory" {
        let totalMemory = Int(ProcessInfo.processInfo.physicalMemory)
        print("iOS: Returning total memory: \(totalMemory)")
        result(totalMemory)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}