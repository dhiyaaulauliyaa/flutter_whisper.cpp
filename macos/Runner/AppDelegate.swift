import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Setup performance monitoring method channel
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      fatalError("mainFlutterWindow is not type FlutterViewController")
    }
    
    let performanceChannel = FlutterMethodChannel(name: "performance_monitor", binaryMessenger: controller.engine.binaryMessenger)
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
    
    dummy_method_to_enforce_bundling()
    
    super.applicationDidFinishLaunching(notification)
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
