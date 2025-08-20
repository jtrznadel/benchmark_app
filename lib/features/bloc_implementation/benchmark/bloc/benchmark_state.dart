import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark/core/models/enriched_movie.dart';
import '../../../../core/models/movie.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class BenchmarkState extends Equatable {
  final BenchmarkStatus status;
  final ScenarioType scenarioType; // ZMIANA: String -> ScenarioType
  final int dataSize;
  final List<Movie> movies;
  final List<Movie> filteredMovies;
  final List<EnrichedMovie> enrichedMovies; // NOWE
  final ViewMode viewMode;
  final bool isAccessibilityMode;
  final Set<int> expandedMovies;
  final String? error;
  final DateTime? startTime;
  final DateTime? endTime;
  final int loadedCount;
  final bool isAutoScrolling;

  // NOWE - dla nowych scenariuszy
  final int progressCounter;
  final String statusText;
  final List<int> multiCounters;
  final List<bool> loadingStates;
  final int currentFilterIndex;
  final bool isStreamingActive;

  const BenchmarkState({
    this.status = BenchmarkStatus.initial,
    this.scenarioType = ScenarioType.apiStreaming, // ZMIANA
    this.dataSize = 0,
    this.movies = const [],
    this.filteredMovies = const [],
    this.enrichedMovies = const [], // NOWE
    this.viewMode = ViewMode.list,
    this.isAccessibilityMode = false,
    this.expandedMovies = const {},
    this.error,
    this.startTime,
    this.endTime,
    this.loadedCount = 0,
    this.isAutoScrolling = false,
    this.progressCounter = 0, // NOWE
    this.statusText = '', // NOWE
    this.multiCounters = const [], // NOWE
    this.loadingStates = const [], // NOWE
    this.currentFilterIndex = 0, // NOWE
    this.isStreamingActive = false, // NOWE
  });

  BenchmarkState copyWith({
    BenchmarkStatus? status,
    ScenarioType? scenarioType, // ZMIANA
    int? dataSize,
    List<Movie>? movies,
    List<Movie>? filteredMovies,
    List<EnrichedMovie>? enrichedMovies, // NOWE
    ViewMode? viewMode,
    bool? isAccessibilityMode,
    Set<int>? expandedMovies,
    String? error,
    DateTime? startTime,
    DateTime? endTime,
    int? loadedCount,
    bool? isAutoScrolling,
    int? progressCounter, // NOWE
    String? statusText, // NOWE
    List<int>? multiCounters, // NOWE
    List<bool>? loadingStates, // NOWE
    int? currentFilterIndex, // NOWE
    bool? isStreamingActive, // NOWE
  }) {
    return BenchmarkState(
      status: status ?? this.status,
      scenarioType: scenarioType ?? this.scenarioType,
      dataSize: dataSize ?? this.dataSize,
      movies: movies ?? this.movies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      enrichedMovies: enrichedMovies ?? this.enrichedMovies,
      viewMode: viewMode ?? this.viewMode,
      isAccessibilityMode: isAccessibilityMode ?? this.isAccessibilityMode,
      expandedMovies: expandedMovies ?? this.expandedMovies,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      loadedCount: loadedCount ?? this.loadedCount,
      isAutoScrolling: isAutoScrolling ?? this.isAutoScrolling,
      progressCounter: progressCounter ?? this.progressCounter,
      statusText: statusText ?? this.statusText,
      multiCounters: multiCounters ?? this.multiCounters,
      loadingStates: loadingStates ?? this.loadingStates,
      currentFilterIndex: currentFilterIndex ?? this.currentFilterIndex,
      isStreamingActive: isStreamingActive ?? this.isStreamingActive,
    );
  }

  @override
  List<Object?> get props => [
        status,
        scenarioType,
        dataSize,
        movies,
        filteredMovies,
        enrichedMovies,
        viewMode,
        isAccessibilityMode,
        expandedMovies,
        error,
        startTime,
        endTime,
        loadedCount,
        isAutoScrolling,
        progressCounter,
        statusText,
        multiCounters,
        loadingStates,
        currentFilterIndex,
        isStreamingActive,
      ];
}
