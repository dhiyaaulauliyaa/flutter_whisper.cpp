import 'dart:async';
import 'package:flutter/material.dart';
import 'performance_monitor.dart';

class PerformanceOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onToggleVisibility;
  
  const PerformanceOverlay({
    Key? key,
    required this.isVisible,
    this.onToggleVisibility,
  }) : super(key: key);

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  StreamSubscription<PerformanceData>? _subscription;
  PerformanceData? _currentData;
  
  double _overlayX = 20.0;
  double _overlayY = 100.0;
  bool _isExpanded = true;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      _startMonitoring();
    }
  }

  @override
  void didUpdateWidget(PerformanceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startMonitoring();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _stopMonitoring();
    }
  }

  void _startMonitoring() {
    _monitor.startMonitoring();
    _subscription = _monitor.performanceStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentData = data;
        });
      }
    });
  }

  void _stopMonitoring() {
    _subscription?.cancel();
    _monitor.stopMonitoring();
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      left: _overlayX,
      top: _overlayY,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
        },
        onPanUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _overlayX = (_overlayX + details.delta.dx).clamp(0.0, 
                MediaQuery.of(context).size.width - (_isExpanded ? 200.0 : 60.0));
              _overlayY = (_overlayY + details.delta.dy).clamp(0.0,
                MediaQuery.of(context).size.height - (_isExpanded ? 120.0 : 60.0));
            });
          }
        },
        onPanEnd: (details) {
          _isDragging = false;
        },
        onTap: () {
          if (!_isDragging) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isExpanded ? 200.0 : 60.0,
          height: _isExpanded ? 120.0 : 60.0,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.green.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: _isExpanded ? _buildExpandedView() : _buildCompactView(),
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'PERF',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    if (_currentData == null) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance Monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: widget.onToggleVisibility,
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Performance metrics
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricRow(
                  'CPU',
                  '${_currentData!.cpuUsage.toStringAsFixed(1)}%',
                  _getColorForPercentage(_currentData!.cpuUsage),
                ),
                _buildMetricRow(
                  'RAM',
                  '${_currentData!.memoryUsageMB.toStringAsFixed(0)}MB '
                  '(${_currentData!.memoryUsagePercent.toStringAsFixed(1)}%)',
                  _getColorForPercentage(_currentData!.memoryUsagePercent),
                ),
                _buildMetricRow(
                  'FPS',
                  '${_currentData!.fps}',
                  _getColorForFps(_currentData!.fps),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForFps(int fps) {
    if (fps >= 50) return Colors.green;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }
}