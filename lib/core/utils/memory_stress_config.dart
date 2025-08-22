import 'enums.dart';

class MemoryStressConfig {
  final Duration operationInterval;
  final int maxHistoryStates;
  final int complexObjectsPerCycle;
  final int deepCopyOperations;
  final int largeListAllocations;
  final int stringConcatenations;
  final int mapCreations;
  final double stateRetentionPercent;
  final String description;

  const MemoryStressConfig({
    required this.operationInterval,
    required this.maxHistoryStates,
    required this.complexObjectsPerCycle,
    required this.deepCopyOperations,
    required this.largeListAllocations,
    required this.stringConcatenations,
    required this.mapCreations,
    required this.stateRetentionPercent,
    required this.description,
  });

  static MemoryStressConfig getConfig(TestStressLevel level) {
    switch (level) {
      case TestStressLevel.light:
        return const MemoryStressConfig(
          operationInterval: Duration(milliseconds: 200),
          maxHistoryStates: 50,
          complexObjectsPerCycle: 10,
          deepCopyOperations: 2,
          largeListAllocations: 5,
          stringConcatenations: 100,
          mapCreations: 3,
          stateRetentionPercent: 0.8, // 80% retention
          description: 'Lekkie obciążenie: powolne operacje, mała historia',
        );
      case TestStressLevel.medium:
        return const MemoryStressConfig(
          operationInterval: Duration(milliseconds: 100),
          maxHistoryStates: 150,
          complexObjectsPerCycle: 25,
          deepCopyOperations: 5,
          largeListAllocations: 15,
          stringConcatenations: 300,
          mapCreations: 8,
          stateRetentionPercent: 0.6, // 60% retention
          description:
              'Średnie obciążenie: umiarkowane operacje, średnia historia',
        );
      case TestStressLevel.heavy:
        return const MemoryStressConfig(
          operationInterval: Duration(milliseconds: 50),
          maxHistoryStates: 300,
          complexObjectsPerCycle: 50,
          deepCopyOperations: 10,
          largeListAllocations: 30,
          stringConcatenations: 600,
          mapCreations: 15,
          stateRetentionPercent:
              0.4, // 40% retention - więcej garbage collection
          description: 'Wysokie obciążenie: agresywne operacje, duża historia',
        );
    }
  }

  static String getLevelLabel(TestStressLevel level) {
    switch (level) {
      case TestStressLevel.light:
        return 'Lekki (M1)';
      case TestStressLevel.medium:
        return 'Średni (M2)';
      case TestStressLevel.heavy:
        return 'Wysoki (M3)';
    }
  }
}
