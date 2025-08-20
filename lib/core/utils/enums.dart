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
  apiStreaming, // S01 - API Data Streaming
  realtimeFiltering, // S02 - Real-time Data Filtering
  memoryPressure, // S03 - Memory Pressure Simulation
  cascadingUpdates, // S04 - Cascading State Updates
  highFrequency, // S05 - High-Frequency Updates
}
