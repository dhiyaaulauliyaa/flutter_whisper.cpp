package com.example.whisper_gpt

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PERFORMANCE_CHANNEL = "performance_monitor"
    private lateinit var performanceMonitor: PerformanceMonitor
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        performanceMonitor = PerformanceMonitor(this)
        
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, PERFORMANCE_CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSystemInfo" -> {
                        try {
                            result.success(performanceMonitor.getSystemInfo())
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to get system info: ${e.message}", null)
                        }
                    }
                    "getMemoryUsage" -> {
                        try {
                            result.success(performanceMonitor.getMemoryUsage())
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to get memory usage: ${e.message}", null)
                        }
                    }
                    "getCpuUsage" -> {
                        try {
                            result.success(performanceMonitor.getCpuUsage())
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to get CPU usage: ${e.message}", null)
                        }
                    }
                    "getTotalMemory" -> {
                        try {
                            result.success(performanceMonitor.getTotalMemory())
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to get total memory: ${e.message}", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }
}
