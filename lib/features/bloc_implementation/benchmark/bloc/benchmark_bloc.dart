import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'package:moviedb_benchmark/core/models/processing_state.dart';
import 'package:moviedb_benchmark/core/models/ui_element_state.dart';
import 'benchmark_event.dart';
import 'benchmark_state.dart';

class BenchmarkBloc extends Bloc<BenchmarkEvent, BenchmarkState> {
  final TmdbApiClient apiClient;
  Timer? _scenarioTimer;
  final Random _random = Random(42); // Fixed seed for consistency

  // Predefined configurations for deterministic testing
  final List<String> _genreNames = [
    'Action',
    'Comedy',
    'Drama',
    'Horror',
    'Romance',
    'Sci-Fi'
  ];
  final List<String> _sortTypes = ['rating', 'date', 'title', 'popularity'];
  final List<String> _groupTypes = ['decade', 'genre', 'rating_range'];
  final List<String> _filterTypes = ['genre', 'year', 'rating', 'language'];

  BenchmarkBloc({required this.apiClient}) : super(BenchmarkState()) {
    on<StartBenchmark>(_onStartBenchmark);

    // S01 - CPU Processing Pipeline
    on<ProcessMoviesByGenre>(_onProcessMoviesByGenre);
    on<CalculateAverageRating>(_onCalculateAverageRating);
    on<SortMoviesByMetric>(_onSortMoviesByMetric);
    on<GroupMoviesByDecade>(_onGroupMoviesByDecade);
    on<UpdateFinalProcessingState>(_onUpdateFinalProcessingState);

    // S02 - Memory State History
    on<ApplyFilterConfiguration>(_onApplyFilterConfiguration);
    on<ApplySortConfiguration>(_onApplySortConfiguration);
    on<ApplyGroupConfiguration>(_onApplyGroupConfiguration);
    on<ApplyPaginationConfiguration>(_onApplyPaginationConfiguration);
    on<UndoLastOperation>(_onUndoLastOperation);
    on<UndoToStep>(_onUndoToStep);

    // S03 - UI Updates
    on<UpdateMovieLikeStatus>(_onUpdateMovieLikeStatus);
    on<UpdateMovieViewCount>(_onUpdateMovieViewCount);
    on<UpdateMovieProgress>(_onUpdateMovieProgress);
    on<UpdateMovieDownloadStatus>(_onUpdateMovieDownloadStatus);
    on<UpdateMovieRating>(_onUpdateMovieRating);

    on<BenchmarkCompleted>(_onBenchmarkCompleted);
  }

  Future<void> _onStartBenchmark(
      StartBenchmark event, Emitter<BenchmarkState> emit) async {
    emit(state.copyWith(
      status: BenchmarkStatus.loading,
      scenarioType: event.scenarioType,
      dataSize: event.dataSize,
      startTime: DateTime.now(),
    ));

    MemoryMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
    UIPerformanceTracker.startTracking();

    try {
      // Load initial data
      final movies = await apiClient.loadAllMovies(totalItems: event.dataSize);

      emit(state.copyWith(
        status: BenchmarkStatus.running,
        movies: movies,
        loadedCount: movies.length,
        genreRotation: _genreNames,
      ));

      switch (event.scenarioType) {
        case ScenarioType.cpuProcessingPipeline:
          await _runCpuProcessingPipeline();
          break;
        case ScenarioType.memoryStateHistory:
          await _runMemoryStateHistory();
          break;
        case ScenarioType.uiGranularUpdates:
          await _runUiGranularUpdates();
          break;
      }
    } catch (e) {
      emit(state.copyWith(
        status: BenchmarkStatus.error,
        error: e.toString(),
      ));
      _completeTestWithReports();
    }
  }

  // S01 - CPU Processing Pipeline Implementation
  Future<void> _runCpuProcessingPipeline() async {
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.currentProcessingCycle >= 600) {
        // 60 seconds
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      final genreIndex = state.currentProcessingCycle % _genreNames.length;
      add(ProcessMoviesByGenre(_genreNames[genreIndex]));
    });
  }

  void _onProcessMoviesByGenre(
      ProcessMoviesByGenre event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    // Step 1: Filter by genre
    final filtered = state.movies
        .where((movie) =>
            movie.genreIds.any((id) => _getGenreForId(id) == event.genre))
        .toList();

    final newProcessingState = state.processingState.copyWith(
      filteredMovies: filtered,
      currentGenre: event.genre,
      processingStep: 1,
    );

    emit(state.copyWith(
      processingState: newProcessingState,
      currentProcessingCycle: state.currentProcessingCycle + 1,
    ));

    // Trigger next step
    add(CalculateAverageRating());
  }

  void _onCalculateAverageRating(
      CalculateAverageRating event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    // Step 2: Calculate average rating
    final filtered = state.processingState.filteredMovies;
    final averageRating = filtered.isEmpty
        ? 0.0
        : filtered.map((m) => m.voteAverage).reduce((a, b) => a + b) /
            filtered.length;

    final metrics =
        Map<String, double>.from(state.processingState.calculatedMetrics);
    metrics['averageRating'] = averageRating;

    final newProcessingState = state.processingState.copyWith(
      calculatedMetrics: metrics,
      processingStep: 2,
    );

    emit(state.copyWith(processingState: newProcessingState));

    // Trigger next step
    add(SortMoviesByMetric());
  }

  void _onSortMoviesByMetric(
      SortMoviesByMetric event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    // Step 3: Sort by calculated metric
    final filtered = [...state.processingState.filteredMovies];
    final averageRating =
        state.processingState.calculatedMetrics['averageRating'] ?? 0.0;

    filtered.sort((a, b) {
      final aDiff = (a.voteAverage - averageRating).abs();
      final bDiff = (b.voteAverage - averageRating).abs();
      return aDiff.compareTo(bDiff);
    });

    final newProcessingState = state.processingState.copyWith(
      sortedMovies: filtered,
      processingStep: 3,
    );

    emit(state.copyWith(processingState: newProcessingState));

    // Trigger next step
    add(GroupMoviesByDecade());
  }

  void _onGroupMoviesByDecade(
      GroupMoviesByDecade event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    // Step 4: Group by decade
    final sorted = state.processingState.sortedMovies;
    final grouped = <String, List<Movie>>{};

    for (final movie in sorted) {
      final year = int.tryParse(movie.releaseDate.split('-').first) ?? 2000;
      final decade = '${(year ~/ 10) * 10}s';

      grouped.putIfAbsent(decade, () => []);
      grouped[decade]!.add(movie);
    }

    final newProcessingState = state.processingState.copyWith(
      groupedMovies: grouped,
      processingStep: 4,
    );

    emit(state.copyWith(processingState: newProcessingState));

    // Trigger final step
    add(UpdateFinalProcessingState());
  }

  void _onUpdateFinalProcessingState(
      UpdateFinalProcessingState event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final newProcessingState = state.processingState.copyWith(
      processingStep: 5,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(processingState: newProcessingState));
  }

  // S02 - Memory State History Implementation
  Future<void> _runMemoryStateHistory() async {
    int cycle = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (cycle >= 400) {
        // ~60 seconds
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      // Forward operations (4 steps)
      add(ApplyFilterConfiguration(
          _filterTypes[cycle % _filterTypes.length], cycle));
      add(ApplySortConfiguration(_sortTypes[cycle % _sortTypes.length]));
      add(ApplyGroupConfiguration(_groupTypes[cycle % _groupTypes.length]));
      add(ApplyPaginationConfiguration(cycle % 10));

      // Backward operations (rollback every 8th cycle)
      if (cycle % 8 == 7) {
        add(UndoToStep(max(0, state.currentHistoryIndex - 4)));
      }

      cycle++;
    });
  }

  void _onApplyFilterConfiguration(
      ApplyFilterConfiguration event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    // Create new complete state for history
    final currentState = state.processingState;
    final newState = ProcessingState(
      rawMovies: state.movies,
      filteredMovies:
          _applyFilter(state.movies, event.filterType, event.filterValue),
      sortedMovies: currentState.sortedMovies,
      groupedMovies: currentState.groupedMovies,
      calculatedMetrics: currentState.calculatedMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [...state.operationLog, 'Filter: ${event.filterType}'];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onApplySortConfiguration(
      ApplySortConfiguration event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final currentState = state.processingState;
    final sorted = [...currentState.filteredMovies];
    _applySorting(sorted, event.sortType);

    final newState = currentState.copyWith(
      sortedMovies: sorted,
      currentSortType: event.sortType,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [...state.operationLog, 'Sort: ${event.sortType}'];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onApplyGroupConfiguration(
      ApplyGroupConfiguration event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final currentState = state.processingState;
    final grouped = _applyGrouping(currentState.sortedMovies, event.groupType);

    final newState = currentState.copyWith(
      groupedMovies: grouped,
      currentGroupType: event.groupType,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [...state.operationLog, 'Group: ${event.groupType}'];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onApplyPaginationConfiguration(
      ApplyPaginationConfiguration event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final currentState = state.processingState;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['currentPage'] = event.page.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [...state.operationLog, 'Paginate: ${event.page}'];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onUndoToStep(UndoToStep event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    if (event.stepNumber >= 0 && event.stepNumber < state.stateHistory.length) {
      final restoredState = state.stateHistory[event.stepNumber];
      final newLog = [
        ...state.operationLog,
        'Undo to step: ${event.stepNumber}'
      ];

      emit(state.copyWith(
        processingState: restoredState,
        currentHistoryIndex: event.stepNumber,
        operationLog: newLog,
      ));
    }
  }

  void _onUndoLastOperation(
      UndoLastOperation event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    if (state.currentHistoryIndex > 0) {
      add(UndoToStep(state.currentHistoryIndex - 1));
    }
  }

  // S03 - UI Granular Updates Implementation
  Future<void> _runUiGranularUpdates() async {
    // Initialize UI states for all movies
    final initialStates = <int, UIElementState>{};
    for (final movie in state.movies) {
      initialStates[movie.id] = UIElementState(movieId: movie.id);
    }

    emit(state.copyWith(uiElementStates: initialStates));

    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // 60 FPS
      if (state.frameCounter >= 1800) {
        // 30 seconds
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      // Update different percentages of movies per frame
      final movieCount = state.movies.length;
      final likeUpdates = _getRandomMovieIds(movieCount, 0.10); // 10%
      final viewUpdates = _getRandomMovieIds(movieCount, 0.20); // 20%
      final progressUpdates = _getRandomMovieIds(movieCount, 0.05); // 5%
      final downloadUpdates = _getRandomMovieIds(movieCount, 0.03); // 3%
      final ratingUpdates = _getRandomMovieIds(movieCount, 0.01); // 1%

      add(UpdateMovieLikeStatus(likeUpdates));
      add(UpdateMovieViewCount(viewUpdates));
      add(UpdateMovieProgress(progressUpdates));
      add(UpdateMovieDownloadStatus(downloadUpdates));
      add(UpdateMovieRating(ratingUpdates));
    });
  }

  void _onUpdateMovieLikeStatus(
      UpdateMovieLikeStatus event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final newStates = Map<int, UIElementState>.from(state.uiElementStates);
    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          isLiked: !currentState.isLiked,
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(
      uiElementStates: newStates,
      frameCounter: state.frameCounter + 1,
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieViewCount(
      UpdateMovieViewCount event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final newStates = Map<int, UIElementState>.from(state.uiElementStates);
    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          viewCount: currentState.viewCount + 1,
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(
      uiElementStates: newStates,
      frameCounter: state.frameCounter + 1,
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieProgress(
      UpdateMovieProgress event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final newStates = Map<int, UIElementState>.from(state.uiElementStates);
    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        final newProgress = (currentState.progress + 0.05).clamp(0.0, 1.0);
        newStates[movieId] = currentState.copyWith(
          progress: newProgress,
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(
      uiElementStates: newStates,
      frameCounter: state.frameCounter + 1,
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieDownloadStatus(
      UpdateMovieDownloadStatus event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final newStates = Map<int, UIElementState>.from(state.uiElementStates);
    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          isDownloading: !currentState.isDownloading,
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(
      uiElementStates: newStates,
      frameCounter: state.frameCounter + 1,
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieRating(
      UpdateMovieRating event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate();

    final newStates = Map<int, UIElementState>.from(state.uiElementStates);
    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        final newRating = (currentState.rating + 0.5).clamp(0.0, 10.0);
        newStates[movieId] = currentState.copyWith(
          rating: newRating,
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(
      uiElementStates: newStates,
      frameCounter: state.frameCounter + 1,
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onBenchmarkCompleted(
      BenchmarkCompleted event, Emitter<BenchmarkState> emit) {
    _scenarioTimer?.cancel();
    emit(state.copyWith(
      status: BenchmarkStatus.completed,
      endTime: DateTime.now(),
    ));
    _completeTestWithReports();
  }

  void _completeTestWithReports() {
    MemoryMonitor.stopMonitoring();
    UIPerformanceTracker.stopTracking();

    final memoryReport = MemoryMonitor.generateReport();
    final upmReport = UIPerformanceTracker.generateReport();

    print('=== BLoC Memory Report for ${state.scenarioType} ===');
    print(memoryReport.toFormattedString());
    print('=== BLoC UMP Report for ${state.scenarioType} ===');
    print(upmReport.toFormattedString());
  }

  // Helper methods
  List<Movie> _applyFilter(
      List<Movie> movies, String filterType, dynamic filterValue) {
    switch (filterType) {
      case 'genre':
        final genreName = _genreNames[filterValue % _genreNames.length];
        return movies
            .where((movie) =>
                movie.genreIds.any((id) => _getGenreForId(id) == genreName))
            .toList();
      case 'year':
        final year = 2000 + (filterValue % 25);
        return movies
            .where((movie) => movie.releaseDate.startsWith(year.toString()))
            .toList();
      case 'rating':
        final minRating = 5.0 + (filterValue % 4);
        return movies.where((movie) => movie.voteAverage >= minRating).toList();
      default:
        return movies;
    }
  }

  void _applySorting(List<Movie> movies, String sortType) {
    switch (sortType) {
      case 'rating':
        movies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        break;
      case 'date':
        movies.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        break;
      case 'title':
        movies.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'popularity':
        movies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        break;
    }
  }

  Map<String, List<Movie>> _applyGrouping(
      List<Movie> movies, String groupType) {
    final groups = <String, List<Movie>>{};

    for (final movie in movies) {
      String key;
      switch (groupType) {
        case 'decade':
          final year = int.tryParse(movie.releaseDate.split('-').first) ?? 2000;
          key = '${(year ~/ 10) * 10}s';
          break;
        case 'genre':
          key = movie.genreIds.isNotEmpty
              ? _getGenreForId(movie.genreIds.first)
              : 'Unknown';
          break;
        case 'rating_range':
          final rating = movie.voteAverage;
          if (rating >= 8.0)
            key = 'Excellent (8.0+)';
          else if (rating >= 6.0)
            key = 'Good (6.0-7.9)';
          else if (rating >= 4.0)
            key = 'Average (4.0-5.9)';
          else
            key = 'Poor (<4.0)';
          break;
        default:
          key = 'All';
      }

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(movie);
    }

    return groups;
  }

  List<int> _getRandomMovieIds(int totalCount, double percentage) {
    final count = (totalCount * percentage).round();
    final movieIds = <int>[];

    for (int i = 0; i < count; i++) {
      final randomIndex = _random.nextInt(state.movies.length);
      movieIds.add(state.movies[randomIndex].id);
    }

    return movieIds;
  }

  String _getGenreForId(int genreId) {
    // Simplified genre mapping
    const genreMap = {
      28: 'Action',
      35: 'Comedy',
      18: 'Drama',
      27: 'Horror',
      10749: 'Romance',
      878: 'Sci-Fi',
    };
    return genreMap[genreId] ?? 'Unknown';
  }

  @override
  Future<void> close() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    return super.close();
  }
}
