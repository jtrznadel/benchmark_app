// import 'dart:async';

// class UIRResult {
//   final double rebuildPrecisionScore;
//   final double statePropagationScore;
//   final double uirIndex;
//   final int totalRebuilds;
//   final int targetedRebuilds;
//   final double avgLatencyMs;
//   final List<int> latencies;

//   UIRResult({
//     required this.rebuildPrecisionScore,
//     required this.statePropagationScore,
//     required this.uirIndex,
//     required this.totalRebuilds,
//     required this.targetedRebuilds,
//     required this.avgLatencyMs,
//     required this.latencies,
//   });

//   String toFormattedString() {
//     return '''
// UIR Report
// ==========
// UIR Index: ${uirIndex.toStringAsFixed(2)}
// Rebuild Precision Score: ${rebuildPrecisionScore.toStringAsFixed(2)}
// State Propagation Score: ${statePropagationScore.toStringAsFixed(2)}
// Total Rebuilds: $totalRebuilds
// Targeted Rebuilds: $targetedRebuilds
// Avg Latency: ${avgLatencyMs.toStringAsFixed(2)}ms
// Latency Samples: ${latencies.length}
// ''';
//   }
// }

// class UIRTracker {
//   static final List<_RebuildEvent> _rebuilds = [];
//   static final List<int> _latencies = [];
//   static final Map<String, DateTime> _stateChanges = {};
//   static bool _isTracking = false;

//   static void startTracking() {
//     _rebuilds.clear();
//     _latencies.clear();
//     _stateChanges.clear();
//     _isTracking = true;
//     print('UIR Tracking started');
//   }

//   static void stopTracking() {
//     _isTracking = false;
//     print(
//         'UIR Tracking stopped. Rebuilds: ${_rebuilds.length}, Latencies: ${_latencies.length}');
//   }

//   static void markStateChange(String stateId) {
//     if (!_isTracking) return;
//     _stateChanges[stateId] = DateTime.now();
//   }

//   static void markWidgetRebuild(String widgetId, String? triggeredByState) {
//     if (!_isTracking) return;

//     final now = DateTime.now();
//     bool isTargeted = false;
//     int? latencyMicros;

//     if (triggeredByState != null &&
//         _stateChanges.containsKey(triggeredByState)) {
//       isTargeted = true;
//       latencyMicros =
//           now.difference(_stateChanges[triggeredByState]!).inMicroseconds;
//       _latencies.add(latencyMicros);
//       // Don't remove state change - multiple widgets might be triggered by same change
//     }

//     _rebuilds.add(_RebuildEvent(
//       widgetId: widgetId,
//       timestamp: now,
//       isTargeted: isTargeted,
//       latencyMicros: latencyMicros,
//     ));
//   }

//   static UIRResult generateReport() {
//     if (_rebuilds.isEmpty) return _emptyResult();

//     final totalRebuilds = _rebuilds.length;
//     final targetedRebuilds = _rebuilds.where((r) => r.isTargeted).length;

//     // Rebuild Precision Score
//     final rps =
//         totalRebuilds > 0 ? (targetedRebuilds / totalRebuilds * 100) : 0.0;

//     // State Propagation Latency Score
//     final avgLatencyMs = _latencies.isNotEmpty
//         ? _latencies.reduce((a, b) => a + b) / _latencies.length / 1000.0
//         : 0.0;
//     final splScore = _latencies.isNotEmpty
//         ? (100 - (avgLatencyMs / 5.0 * 100)).clamp(0.0, 100.0)
//         : 100.0;

//     // UIR Index
//     final uir = 0.6 * rps + 0.4 * splScore;

//     return UIRResult(
//       rebuildPrecisionScore: rps,
//       statePropagationScore: splScore,
//       uirIndex: uir,
//       totalRebuilds: totalRebuilds,
//       targetedRebuilds: targetedRebuilds,
//       avgLatencyMs: avgLatencyMs,
//       latencies: _latencies.map((l) => l ~/ 1000).toList(),
//     );
//   }

//   static UIRResult _emptyResult() {
//     return UIRResult(
//       rebuildPrecisionScore: 0,
//       statePropagationScore: 0,
//       uirIndex: 0,
//       totalRebuilds: 0,
//       targetedRebuilds: 0,
//       avgLatencyMs: 0,
//       latencies: [],
//     );
//   }
// }

// class _RebuildEvent {
//   final String widgetId;
//   final DateTime timestamp;
//   final bool isTargeted;
//   final int? latencyMicros;

//   _RebuildEvent({
//     required this.widgetId,
//     required this.timestamp,
//     required this.isTargeted,
//     this.latencyMicros,
//   });
// }
