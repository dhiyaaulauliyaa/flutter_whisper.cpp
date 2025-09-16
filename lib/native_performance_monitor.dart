import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PerformanceData {
  final double cpuUsage;
  final double memoryUsageMB;
  final double totalMemoryMB;
  final double memoryUsagePercent;
  final int fps;
  final DateTime timestamp;

  PerformanceData({
    required this.cpuUsage,
    required this.memoryUsageMB,
    required this.totalMemoryMB,
    required this.memoryUsagePercent,
    required this.fps,
    required this.timestamp,
  });
}

class NativePerformanceMonitor {
  static final NativePerformanceMonitor _instance = NativePerformanceMonitor._internal();
  factory NativePerformanceMonitor() => _instance;
  NativePerformanceMonitor._internal();

  Timer? _timer;
  final StreamController<PerformanceData> _controller = StreamController<PerformanceData>.broadcast();
  
  // Method channel for native performance monitoring
  static const MethodChannel _methodChannel = MethodChannel('performance_monitor');
  
  // FPS tracking variables
  int _frameCount = 0;
  int _lastFrameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  
  Stream<PerformanceData> get performanceStream => _controller.stream;
  
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Test native monitoring availability
    try {
      await _methodChannel.invokeMethod('getSystemInfo');
      if (kDebugMode) print('✅ Native performance monitoring available');
    } catch (e) {
      if (kDebugMode) print('❌ Native performance monitoring failed: $e');
      throw Exception('Native performance monitoring not available: $e');
    }
    
    // Start periodic monitoring
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _updatePerformanceData();
    });
    
    // Start FPS monitoring
    _startFpsMonitoring();
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _timer?.cancel();
    _timer = null;
  }

  void _startFpsMonitoring() {
    // Simple FPS approximation
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      final timeDiff = now.difference(_lastFpsUpdate).inMilliseconds;
      if (timeDiff >= 1000) {
        _lastFrameCount = _frameCount;
        _frameCount = 0;
        _lastFpsUpdate = now;
      }
    });
  }

  void _updatePerformanceData() async {
    try {
      // Get native performance data
      final systemInfo = await _methodChannel.invokeMethod('getSystemInfo') as Map<Object?, Object?>;
      
      final cpuUsage = (systemInfo['cpuUsagePercent'] as num).toDouble();
      final memoryUsageMB = (systemInfo['usedMemoryMB'] as num).toDouble(); 
      final totalMemoryMB = (systemInfo['totalMemoryMB'] as num).toDouble();
      final memoryUsagePercent = (systemInfo['memoryUsagePercent'] as num).toDouble();
      
      // Estimate FPS (simplified)
      _frameCount++;
      final fps = _lastFrameCount;

      final data = PerformanceData(
        cpuUsage: cpuUsage,
        memoryUsageMB: memoryUsageMB,
        totalMemoryMB: totalMemoryMB,
        memoryUsagePercent: memoryUsagePercent,
        fps: fps,
        timestamp: DateTime.now(),
      );

      if (!_controller.isClosed) {
        _controller.add(data);
      }
      
      if (kDebugMode) {
        print('📊 Native data - CPU: ${cpuUsage.toStringAsFixed(1)}%, Memory: ${memoryUsageMB.toStringAsFixed(0)}MB (${memoryUsagePercent.toStringAsFixed(1)}%)');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error getting native performance data: $e');
      
      // Create fallback data to avoid breaking the UI
      final data = PerformanceData(
        cpuUsage: 0.0,
        memoryUsageMB: 0.0,
        totalMemoryMB: 8192.0,
        memoryUsagePercent: 0.0,
        fps: 0,
        timestamp: DateTime.now(),
      );
      
      if (!_controller.isClosed) {
        _controller.add(data);
      }
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}