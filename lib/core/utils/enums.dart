enum BenchmarkStatus {
  initial,
  loading,
  loaded,
  running,
  completed,
  error,
}

enum ViewMode { list, grid }

enum ScenarioType {
  cpuProcessingPipeline, // S01 - CPU Test
  memoryStateHistory, // S02 - Memory Test
  uiGranularUpdates, // S03 - UI Test
}

enum TestStressLevel {
  light, // L1 - Lekki
  medium, // L2 - Średni
  heavy, // L3 - Wysoki
}
