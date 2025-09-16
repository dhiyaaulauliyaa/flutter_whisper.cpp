import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let dummy = dummy_method_to_enforce_bundling()
    print(dummy)
    
    // Setup performance monitoring method channel
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    
    let performanceChannel = FlutterMethodChannel(name: "performance_monitor", binaryMessenger: controller.binaryMessenger)
    performanceChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getSystemInfo":
        result(PerformanceMonitor.systemInfo())
      case "getMemoryUsage":
        result(PerformanceMonitor.memoryUsage())
      case "getCpuUsage":
        result(PerformanceMonitor.cpuUsage())
      case "getTotalMemory":
        result(PerformanceMonitor.totalMemory())
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
