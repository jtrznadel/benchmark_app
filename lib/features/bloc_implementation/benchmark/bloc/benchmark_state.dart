import 'package:equatable/equatable.dart';
import '../../../../core/models/movie.dart';
import '../../../../core/models/processing_state.dart';
import '../../../../core/models/ui_element_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class BenchmarkState extends Equatable {
  final BenchmarkStatus status;
  final ScenarioType scenarioType;
  final int dataSize;
  final List<Movie> movies;
  final String? error;
  final DateTime? startTime;
  final DateTime? endTime;
  final int loadedCount;
  final TestStressLevel? stressLevel;

  // S01 - CPU Processing specific
  final ProcessingState processingState;
  final int currentProcessingCycle;
  final List<String> genreRotation;

  // S02 - Memory State History specific
  final List<ProcessingState> stateHistory;
  final int currentHistoryIndex;
  final List<String> operationLog;

  // S03 - UI Updates specific
  final Map<int, UIElementState> uiElementStates;
  final int frameCounter;
  final List<int> lastUpdatedMovieIds;

  BenchmarkState({
    this.status = BenchmarkStatus.initial,
    this.scenarioType = ScenarioType.cpuProcessingPipeline,
    this.dataSize = 0,
    this.movies = const [],
    this.error,
    this.startTime,
    this.endTime,
    this.loadedCount = 0,
    ProcessingState? processingState,
    this.currentProcessingCycle = 0,
    this.genreRotation = const [],
    this.stateHistory = const [],
    this.currentHistoryIndex = 0,
    this.operationLog = const [],
    this.uiElementStates = const {},
    this.frameCounter = 0,
    this.lastUpdatedMovieIds = const [],
    this.stressLevel, // DODANE
  }) : processingState = processingState ?? ProcessingState();

  BenchmarkState copyWith({
    BenchmarkStatus? status,
    ScenarioType? scenarioType,
    int? dataSize,
    List<Movie>? movies,
    String? error,
    DateTime? startTime,
    DateTime? endTime,
    int? loadedCount,
    ProcessingState? processingState,
    int? currentProcessingCycle,
    List<String>? genreRotation,
    List<ProcessingState>? stateHistory,
    int? currentHistoryIndex,
    List<String>? operationLog,
    Map<int, UIElementState>? uiElementStates,
    int? frameCounter,
    List<int>? lastUpdatedMovieIds,
    TestStressLevel? stressLevel,
  }) {
    return BenchmarkState(
      status: status ?? this.status,
      scenarioType: scenarioType ?? this.scenarioType,
      dataSize: dataSize ?? this.dataSize,
      movies: movies ?? this.movies,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      loadedCount: loadedCount ?? this.loadedCount,
      processingState: processingState ?? this.processingState,
      currentProcessingCycle:
          currentProcessingCycle ?? this.currentProcessingCycle,
      genreRotation: genreRotation ?? this.genreRotation,
      stateHistory: stateHistory ?? this.stateHistory,
      currentHistoryIndex: currentHistoryIndex ?? this.currentHistoryIndex,
      operationLog: operationLog ?? this.operationLog,
      uiElementStates: uiElementStates ?? this.uiElementStates,
      frameCounter: frameCounter ?? this.frameCounter,
      lastUpdatedMovieIds: lastUpdatedMovieIds ?? this.lastUpdatedMovieIds,
      stressLevel: stressLevel ?? this.stressLevel,
    );
  }

  @override
  List<Object?> get props => [
        status,
        scenarioType,
        dataSize,
        movies,
        error,
        startTime,
        endTime,
        loadedCount,
        processingState,
        currentProcessingCycle,
        genreRotation,
        stateHistory,
        currentHistoryIndex,
        operationLog,
        uiElementStates,
        frameCounter,
        lastUpdatedMovieIds,
        stressLevel,
      ];
}
