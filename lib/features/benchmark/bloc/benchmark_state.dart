import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark_bloc/core/api/models/movie.dart';

enum BenchmarkStatus {
  initial,
  loading,
  loaded,
  running,
  completed,
  error,
}

enum ViewMode { list, grid }

class BenchmarkState extends Equatable {
  final BenchmarkStatus status;
  final String scenarioId;
  final int dataSize;
  final List<Movie> movies;
  final List<Movie> filteredMovies;
  final ViewMode viewMode;
  final bool isAccessibilityMode;
  final Set<int> expandedMovies;
  final String? error;
  final DateTime? startTime;
  final DateTime? endTime;
  final int loadedCount;
  final bool isAutoScrolling;

  const BenchmarkState({
    this.status = BenchmarkStatus.initial,
    this.scenarioId = '',
    this.dataSize = 0,
    this.movies = const [],
    this.filteredMovies = const [],
    this.viewMode = ViewMode.list,
    this.isAccessibilityMode = false,
    this.expandedMovies = const {},
    this.error,
    this.startTime,
    this.endTime,
    this.loadedCount = 0,
    this.isAutoScrolling = false,
  });

  BenchmarkState copyWith({
    BenchmarkStatus? status,
    String? scenarioId,
    int? dataSize,
    List<Movie>? movies,
    List<Movie>? filteredMovies,
    ViewMode? viewMode,
    bool? isAccessibilityMode,
    Set<int>? expandedMovies,
    String? error,
    DateTime? startTime,
    DateTime? endTime,
    int? loadedCount,
    bool? isAutoScrolling,
  }) {
    return BenchmarkState(
      status: status ?? this.status,
      scenarioId: scenarioId ?? this.scenarioId,
      dataSize: dataSize ?? this.dataSize,
      movies: movies ?? this.movies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      viewMode: viewMode ?? this.viewMode,
      isAccessibilityMode: isAccessibilityMode ?? this.isAccessibilityMode,
      expandedMovies: expandedMovies ?? this.expandedMovies,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      loadedCount: loadedCount ?? this.loadedCount,
      isAutoScrolling: isAutoScrolling ?? this.isAutoScrolling,
    );
  }

  @override
  List<Object?> get props => [
        status,
        scenarioId,
        dataSize,
        movies,
        filteredMovies,
        viewMode,
        isAccessibilityMode,
        expandedMovies,
        error,
        startTime,
        endTime,
        loadedCount,
        isAutoScrolling,
      ];
}
