import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceLogger {
  static const String _prefsKey = 'performance_logs';

  static Future<void> logTestResult({
    required String library,
    required String scenarioId,
    required int dataSize,
    required Duration executionTime,
    Map<String, dynamic>? additionalMetrics,
  }) async {
    final result = {
      'library': library,
      'scenarioId': scenarioId,
      'dataSize': dataSize,
      'executionTimeMs': executionTime.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalMetrics,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingLogs = prefs.getStringList(_prefsKey) ?? [];
      existingLogs.add(jsonEncode(result));
      await prefs.setStringList(_prefsKey, existingLogs);
      
      debugPrint('Performance logged: $result');
    } catch (e) {
      debugPrint('Error logging performance: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_prefsKey) ?? [];
      return logs.map((log) => jsonDecode(log) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error reading logs: $e');
      return [];
    }
  }

  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static Future<void> exportLogsToCSV() async {
    final logs = await getAllLogs();
    if (logs.isEmpty) return;

    final csv = StringBuffer();
    csv.writeln('Library,Scenario,DataSize,ExecutionTimeMs,Timestamp');
    
    for (final log in logs) {
      csv.writeln(
        '${log['library']},${log['scenarioId']},${log['dataSize']},'
        '${log['executionTimeMs']},${log['timestamp']}',
      );
    }

    debugPrint('CSV Export:\n$csv');
  }

  static Future<Map<String, dynamic>> generateReport() async {
    final logs = await getAllLogs();
    if (logs.isEmpty) {
      return {'error': 'Brak danych do analizy'};
    }

    final blocLogs = logs.where((l) => l['library'] == 'BLoC').toList();
    final getxLogs = logs.where((l) => l['library'] == 'GetX').toList();

    final scenarios = ['S01', 'S02', 'S03', 'S04', 'S05'];
    final report = <String, dynamic>{};

    for (final scenario in scenarios) {
      final blocScenarioLogs = blocLogs.where((l) => l['scenarioId'] == scenario).toList();
      final getxScenarioLogs = getxLogs.where((l) => l['scenarioId'] == scenario).toList();

      if (blocScenarioLogs.isNotEmpty && getxScenarioLogs.isNotEmpty) {
        final blocAvg = _calculateAverage(blocScenarioLogs);
        final getxAvg = _calculateAverage(getxScenarioLogs);
        final difference = ((blocAvg - getxAvg) / blocAvg * 100).toStringAsFixed(2);

        report[scenario] = {
          'blocAvg': blocAvg,
          'getxAvg': getxAvg,
          'difference': difference,
          'winner': blocAvg < getxAvg ? 'BLoC' : 'GetX',
        };
      }
    }

    return report;
  }

  static double _calculateAverage(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;
    final sum = logs.fold<int>(
      0,
      (sum, log) => sum + (log['executionTimeMs'] as int),
    );
    return sum / logs.length;
  }
}