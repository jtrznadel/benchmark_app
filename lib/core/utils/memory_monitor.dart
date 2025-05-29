import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';

class MemoryMonitor {
  static final List<MemorySnapshot> _snapshots = [];
  static Timer? _timer;
  static DateTime? _startTime;
  static int? _totalPhysicalMemoryMB;

  static bool get isMonitoring => _timer != null;

  static void reset() {
    stopMonitoring();
    _snapshots.clear();
    _startTime = null;
    _totalPhysicalMemoryMB = null;
  }

  static void startMonitoring(
      {Duration interval = const Duration(seconds: 1)}) {
    _snapshots.clear();
    _startTime = DateTime.now();

    _getPhysicalMemoryInfo();

    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      _captureSnapshot();
    });
  }

  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _getPhysicalMemoryInfo() async {
    try {
      if (Platform.isIOS) {
        await _getIOSMemoryInfo();
      } else {}
    } catch (e) {
      print('Error getting physical memory info: $e');
    }
  }

  static Future<void> _getIOSMemoryInfo() async {
    try {
      const platform = MethodChannel('com.example.benchmark/memory');

      final totalMemoryBytes =
          await platform.invokeMethod<int>('getTotalMemory');

      if (totalMemoryBytes != null) {
        _totalPhysicalMemoryMB = (totalMemoryBytes / 1024 / 1024).round();
        print('Total physical RAM: $_totalPhysicalMemoryMB MB');
      } else {
        throw Exception('Received null memory value');
      }
    } catch (e) {}
  }

  static void _captureSnapshot() {
    try {
      developer.Timeline.instantSync('memory_snapshot');

      final memInfo = ProcessInfo.currentRss;
      final maxRss = ProcessInfo.maxRss;

      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        usedMemoryBytes: memInfo,
        maxMemoryBytes: maxRss,
        totalPhysicalMemoryMB: _totalPhysicalMemoryMB,
      );

      _snapshots.add(snapshot);

      final memMB = memInfo / 1024 / 1024;
      final percentageStr = _totalPhysicalMemoryMB != null
          ? ' (${(memMB / _totalPhysicalMemoryMB! * 100).toStringAsFixed(1)}%)'
          : '';

      print('Memory snapshot: ${memMB.toStringAsFixed(2)} MB$percentageStr');
    } catch (e) {}
  }

  static MemoryReport generateReport() {
    if (_snapshots.isEmpty) return MemoryReport.empty();

    final usedMemoryValues = _snapshots.map((s) => s.usedMemoryBytes).toList();

    return MemoryReport(
      startTime: _startTime!,
      endTime: DateTime.now(),
      snapshots: _snapshots,
      avgMemoryMB: _calculateAverage(usedMemoryValues) / 1024 / 1024,
      minMemoryMB:
          usedMemoryValues.reduce((a, b) => a < b ? a : b) / 1024 / 1024,
      maxMemoryMB:
          usedMemoryValues.reduce((a, b) => a > b ? a : b) / 1024 / 1024,
      samples: _snapshots.length,
      totalPhysicalMemoryMB: _totalPhysicalMemoryMB,
    );
  }

  static double _calculateAverage(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class MemorySnapshot {
  final DateTime timestamp;
  final int usedMemoryBytes;
  final int maxMemoryBytes;
  final int? totalPhysicalMemoryMB;

  MemorySnapshot({
    required this.timestamp,
    required this.usedMemoryBytes,
    required this.maxMemoryBytes,
    this.totalPhysicalMemoryMB,
  });
}

class MemoryReport {
  final DateTime startTime;
  final DateTime endTime;
  final List<MemorySnapshot> snapshots;
  final double avgMemoryMB;
  final double minMemoryMB;
  final double maxMemoryMB;
  final int samples;
  final int? totalPhysicalMemoryMB;

  MemoryReport({
    required this.startTime,
    required this.endTime,
    required this.snapshots,
    required this.avgMemoryMB,
    required this.minMemoryMB,
    required this.maxMemoryMB,
    required this.samples,
    this.totalPhysicalMemoryMB,
  });

  factory MemoryReport.empty() {
    return MemoryReport(
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      snapshots: [],
      avgMemoryMB: 0,
      minMemoryMB: 0,
      maxMemoryMB: 0,
      samples: 0,
      totalPhysicalMemoryMB: null,
    );
  }

  String toFormattedString() {
    final totalRAM = totalPhysicalMemoryMB != null
        ? ' / $totalPhysicalMemoryMB MB total RAM'
        : '';

    final avgPercent = totalPhysicalMemoryMB != null
        ? ' (${(avgMemoryMB / totalPhysicalMemoryMB! * 100).toStringAsFixed(1)}%)'
        : '';

    final minPercent = totalPhysicalMemoryMB != null
        ? ' (${(minMemoryMB / totalPhysicalMemoryMB! * 100).toStringAsFixed(1)}%)'
        : '';

    final maxPercent = totalPhysicalMemoryMB != null
        ? ' (${(maxMemoryMB / totalPhysicalMemoryMB! * 100).toStringAsFixed(1)}%)'
        : '';

    return '''
Memory Report$totalRAM
=============
Duration: ${endTime.difference(startTime).inSeconds}s
Samples: $samples
Average Memory: ${avgMemoryMB.toStringAsFixed(2)} MB$avgPercent
Min Memory: ${minMemoryMB.toStringAsFixed(2)} MB$minPercent
Max Memory: ${maxMemoryMB.toStringAsFixed(2)} MB$maxPercent
''';
  }
}
