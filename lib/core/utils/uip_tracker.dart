import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';

class UIPerformanceResult {
  final double jankRate; // 0-100% (% klatek > 16.67ms)
  final double avgLatencyMs; // średnia latencja action→visual w ms
  final double uiPerformanceScore; // 0-100 (wyższe = lepsze)

  final int totalFrames;
  final int jankFrames;
  final List<double> frameTimesMs;
  final List<double> latenciesMs;
  final Duration testDuration;

  UIPerformanceResult({
    required this.jankRate,
    required this.avgLatencyMs,
    required this.uiPerformanceScore,
    required this.totalFrames,
    required this.jankFrames,
    required this.frameTimesMs,
    required this.latenciesMs,
    required this.testDuration,
  });

  String toFormattedString() {
    return '''
UI Performance Report
=====================
UI Performance Score: ${uiPerformanceScore.toStringAsFixed(2)}
Jank Rate: ${jankRate.toStringAsFixed(2)}% ($jankFrames/$totalFrames frames)
Avg Action Latency: ${avgLatencyMs.toStringAsFixed(2)}ms

Raw Data:
---------
Test Duration: ${testDuration.inMilliseconds}ms
Total Frames: $totalFrames
Jank Frames (>16.67ms): $jankFrames
Latency Samples: ${latenciesMs.length}
Best Frame: ${frameTimesMs.isNotEmpty ? frameTimesMs.reduce(math.min).toStringAsFixed(2) : 0}ms
Worst Frame: ${frameTimesMs.isNotEmpty ? frameTimesMs.reduce(math.max).toStringAsFixed(2) : 0}ms
''';
  }
}

class UIPerformanceTracker {
  static final List<Duration> _frameTimes = [];
  static final List<DateTime> _actionTimestamps = [];
  static final List<double> _measuredLatencies = [];
  static DateTime? _startTime;
  static DateTime? _endTime;
  static DateTime? _lastActionTime;
  static bool _isTracking = false;
  static bool _waitingForFrameAfterAction = false;

  // Callback dla Flutter FrameTiming
  static void _onFrameTiming(List<FrameTiming> timings) {
    if (!_isTracking) return;

    final now = DateTime.now();

    for (final timing in timings) {
      final frameDuration = timing.totalSpan;
      _frameTimes.add(frameDuration);

      // Jeśli czekamy na pierwszą klatkę po akcji, zmierz latencję
      if (_waitingForFrameAfterAction && _lastActionTime != null) {
        final latencyMs =
            now.difference(_lastActionTime!).inMicroseconds / 1000.0;
        _measuredLatencies.add(latencyMs);
        _waitingForFrameAfterAction = false;
        _lastActionTime = null;
      }
    }
  }

  static void startTracking() {
    _frameTimes.clear();
    _actionTimestamps.clear();
    _measuredLatencies.clear();
    _startTime = DateTime.now();
    _endTime = null;
    _lastActionTime = null;
    _waitingForFrameAfterAction = false;
    _isTracking = true;

    // Podłącz do Flutter Performance API
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);

    print('UI Performance Tracking started');
  }

  static void stopTracking() {
    _isTracking = false;
    _endTime = DateTime.now();

    // Odłącz od Flutter Performance API
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);

    print(
        'UI Performance Tracking stopped. Frames: ${_frameTimes.length}, Latencies: ${_measuredLatencies.length}');
  }

  // Wywołane gdy następuje akcja użytkownika lub zmiana stanu
  static void markAction() {
    if (!_isTracking) return;

    _lastActionTime = DateTime.now();
    _actionTimestamps.add(_lastActionTime!);
    _waitingForFrameAfterAction = true;
  }

  static UIPerformanceResult generateReport() {
    if (_startTime == null) {
      return _emptyResult();
    }

    final endTime = _endTime ?? DateTime.now();
    final testDuration = endTime.difference(_startTime!);

    // Konwertuj frame times na ms
    final frameTimesMs =
        _frameTimes.map((d) => d.inMicroseconds / 1000.0).toList();

    // Oblicz Jank Rate (% klatek > 16.67ms)
    const jankThresholdMs = 16.67;
    final jankFrames =
        frameTimesMs.where((frameMs) => frameMs > jankThresholdMs).length;
    final jankRate = frameTimesMs.isNotEmpty
        ? (jankFrames / frameTimesMs.length) * 100
        : 0.0;

    // Oblicz średnią latencję
    final avgLatencyMs = _measuredLatencies.isNotEmpty
        ? _measuredLatencies.reduce((a, b) => a + b) / _measuredLatencies.length
        : 0.0;

    // Oblicz UI Performance Score (0-100, wyższe = lepsze)
    // Formula: 100 - (Jank_Rate × 2) - (Avg_Latency_ms × 5)
    final uiScore = math.max(0.0, 100 - (jankRate * 2) - (avgLatencyMs * 5));

    return UIPerformanceResult(
      jankRate: jankRate,
      avgLatencyMs: avgLatencyMs,
      uiPerformanceScore: uiScore,
      totalFrames: frameTimesMs.length,
      jankFrames: jankFrames,
      frameTimesMs: frameTimesMs,
      latenciesMs: List.from(_measuredLatencies),
      testDuration: testDuration,
    );
  }

  static UIPerformanceResult _emptyResult() {
    return UIPerformanceResult(
      jankRate: 0,
      avgLatencyMs: 0,
      uiPerformanceScore: 0,
      totalFrames: 0,
      jankFrames: 0,
      frameTimesMs: [],
      latenciesMs: [],
      testDuration: Duration.zero,
    );
  }
}
