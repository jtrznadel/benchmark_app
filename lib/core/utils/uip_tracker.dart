import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';

class UPMResult {
  final double frameTimingStability; // 0-100, wyższe = lepsze
  final double widgetRebuildEfficiency; // rebuilds/second, niższe = lepsze
  final double stateUpdateFrequency; // updates/second
  final double upmScore; // kombinacja wszystkich

  final List<Duration> frameTimes;
  final int totalRebuilds;
  final int totalStateUpdates;
  final Duration testDuration;

  UPMResult({
    required this.frameTimingStability,
    required this.widgetRebuildEfficiency,
    required this.stateUpdateFrequency,
    required this.upmScore,
    required this.frameTimes,
    required this.totalRebuilds,
    required this.totalStateUpdates,
    required this.testDuration,
  });

  String toFormattedString() {
    return '''
UPM Report (UI Performance Metric)
==================================
UPM Score: ${upmScore.toStringAsFixed(2)}
Frame Timing Stability: ${frameTimingStability.toStringAsFixed(2)}%
Widget Rebuild Rate: ${widgetRebuildEfficiency.toStringAsFixed(2)} rebuilds/sec
State Update Rate: ${stateUpdateFrequency.toStringAsFixed(2)} updates/sec

Raw Data:
---------
Total Rebuilds: $totalRebuilds
Total State Updates: $totalStateUpdates
Test Duration: ${testDuration.inMilliseconds}ms
Frame Samples: ${frameTimes.length}
Avg Frame Time: ${frameTimes.isNotEmpty ? (frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / frameTimes.length / 1000).toStringAsFixed(2) : 0}ms
''';
  }
}

class UIPerformanceTracker {
  static final List<Duration> _frameTimes = [];
  static final List<DateTime> _rebuildTimestamps = [];
  static final List<DateTime> _stateUpdateTimestamps = [];
  static DateTime? _startTime;
  static DateTime? _endTime;
  static bool _isTracking = false;

  // Callback dla Flutter FrameTiming
  static void _onFrameTiming(List<FrameTiming> timings) {
    if (!_isTracking) return;

    for (final timing in timings) {
      final frameDuration = timing.totalSpan;
      _frameTimes.add(frameDuration);
    }
  }

  static void startTracking() {
    _frameTimes.clear();
    _rebuildTimestamps.clear();
    _stateUpdateTimestamps.clear();
    _startTime = DateTime.now();
    _endTime = null;
    _isTracking = true;

    // Podłącz do Flutter Performance API
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);

    print('UMP Tracking started with Flutter FrameTiming API');
  }

  static void stopTracking() {
    _isTracking = false;
    _endTime = DateTime.now();

    // Odłącz od Flutter Performance API
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);

    print(
        'UMP Tracking stopped. Frames: ${_frameTimes.length}, Rebuilds: ${_rebuildTimestamps.length}, State Updates: ${_stateUpdateTimestamps.length}');
  }

  // Wywołane gdy widget się przebudowuje
  static void markWidgetRebuild() {
    if (!_isTracking) return;
    _rebuildTimestamps.add(DateTime.now());
  }

  // Wywołane gdy stan się zmienia
  static void markStateUpdate() {
    if (!_isTracking) return;
    _stateUpdateTimestamps.add(DateTime.now());
  }

  static UPMResult generateReport() {
    if (_startTime == null) {
      return _emptyResult();
    }

    final endTime = _endTime ?? DateTime.now();
    final testDuration = endTime.difference(_startTime!);
    final testDurationSeconds = testDuration.inMilliseconds / 1000.0;

    // 1. Frame Timing Stability (0-100, wyższe = lepsze)
    final fts = _calculateFrameTimingStability();

    // 2. Widget Rebuild Efficiency (rebuilds per second, niższe = lepsze dla efficiency)
    final wre = testDurationSeconds > 0
        ? _rebuildTimestamps.length / testDurationSeconds
        : 0.0;

    // 3. State Update Frequency (updates per second)
    final suf = testDurationSeconds > 0
        ? _stateUpdateTimestamps.length / testDurationSeconds
        : 0.0;

    // 4. UMP Score (kombinacja, wyższe = lepsze)
    // FTS - wyższe lepsze (0-100)
    // WRE - niższe lepsze, więc odwracamy dla wydajnych aplikacji (idealne ~30 rebuilds/sec)
    final wreScore =
        wre > 0 ? (100 - ((wre - 30).abs() * 2)).clamp(0.0, 100.0) : 100.0;
    final upmScore = (fts * 0.6) + (wreScore * 0.4);

    return UPMResult(
      frameTimingStability: fts,
      widgetRebuildEfficiency: wre,
      stateUpdateFrequency: suf,
      upmScore: upmScore,
      frameTimes: List.from(_frameTimes),
      totalRebuilds: _rebuildTimestamps.length,
      totalStateUpdates: _stateUpdateTimestamps.length,
      testDuration: testDuration,
    );
  }

  static double _calculateFrameTimingStability() {
    if (_frameTimes.length < 10) return 0.0;

    // Konwertuj na millisekundy
    final frameTimesMs =
        _frameTimes.map((d) => d.inMicroseconds / 1000.0).toList();

    // Oblicz średnią
    final mean = frameTimesMs.reduce((a, b) => a + b) / frameTimesMs.length;

    // Oblicz odchylenie standardowe
    final variance = frameTimesMs
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        frameTimesMs.length;
    final stdDev = variance.isFinite ? math.sqrt(variance) : 0.0;

    // Współczynnik zmienności (CV = stdDev / mean)
    final coefficientOfVariation = mean > 0 ? stdDev / mean : 0.0;

    // Przekształć na score 0-100 (niższa zmienność = wyższy score)
    // CV = 0 → score = 100, CV = 0.5 → score = 0
    return (100 * (1 - (coefficientOfVariation * 2))).clamp(0.0, 100.0);
  }

  static UPMResult _emptyResult() {
    return UPMResult(
      frameTimingStability: 0,
      widgetRebuildEfficiency: 0,
      stateUpdateFrequency: 0,
      upmScore: 0,
      frameTimes: [],
      totalRebuilds: 0,
      totalStateUpdates: 0,
      testDuration: Duration.zero,
    );
  }
}
