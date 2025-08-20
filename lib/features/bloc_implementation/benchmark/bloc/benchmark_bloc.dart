import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/models/enriched_movie.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'benchmark_event.dart';
import 'benchmark_state.dart';

class BenchmarkBloc extends Bloc<BenchmarkEvent, BenchmarkState> {
  final TmdbApiClient apiClient;
  int _currentPage = 1;
  bool isLoadingMore = false;
  Timer? _scenarioTimer;
  final Random _random = Random();

  // Predefiniowane filtry dla S02
  final List<Map<String, dynamic>> _predefinedFilters = [
    {'year': 2020, 'genre': null, 'rating': null},
    {'year': null, 'genre': 28, 'rating': null}, // Action
    {'year': null, 'genre': 35, 'rating': null}, // Comedy
    {'year': null, 'genre': 18, 'rating': null}, // Drama
    {'year': null, 'genre': null, 'rating': 7.0},
    {'year': null, 'genre': null, 'rating': 8.0},
    {'year': 2021, 'genre': 28, 'rating': null},
    {'year': 2022, 'genre': 35, 'rating': null},
    {'year': 2023, 'genre': 18, 'rating': 7.5},
    {'year': null, 'genre': 27, 'rating': null}, // Horror
    {'year': null, 'genre': 16, 'rating': null}, // Animation
    {'year': 2024, 'genre': null, 'rating': 6.0},
  ];

  BenchmarkBloc({required this.apiClient}) : super(const BenchmarkState()) {
    on<StartBenchmark>(_onStartBenchmark);
    on<StreamingTick>(_onStreamingTick);
    on<FilteringTick>(_onFilteringTick);
    on<MemoryPressureTick>(_onMemoryPressureTick);
    on<CascadingUpdateTick>(_onCascadingUpdateTick);
    on<HighFrequencyTick>(_onHighFrequencyTick);
    on<EnrichMoviesData>(_onEnrichMoviesData);
    on<SimplifyMoviesData>(_onSimplifyMoviesData);
    on<BenchmarkCompleted>(_onBenchmarkCompleted);

    // Zachowane stare eventy
    on<LoadMoreMovies>(_onLoadMoreMovies);
    on<FilterMovies>(_onFilterMovies);
    on<SortMovies>(_onSortMovies);
    on<ToggleViewMode>(_onToggleViewMode);
    on<ToggleAccessibilityMode>(_onToggleAccessibilityMode);
    on<ToggleMovieExpanded>(_onToggleMovieExpanded);
  }

  Future<void> _onStartBenchmark(
      StartBenchmark event, Emitter<BenchmarkState> emit) async {
    emit(state.copyWith(
      status: BenchmarkStatus.loading,
      scenarioType: event.scenarioType,
      dataSize: event.dataSize,
      startTime: DateTime.now(),
    ));

    // Start tracking
    MemoryMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
    UIPerformanceTracker.startTracking(); // ZMIANA

    try {
      switch (event.scenarioType) {
        case ScenarioType.apiStreaming:
          await _runApiStreamingScenario(event.dataSize, emit);
          break;
        case ScenarioType.realtimeFiltering:
          await _runRealtimeFilteringScenario(event.dataSize, emit);
          break;
        case ScenarioType.memoryPressure:
          await _runMemoryPressureScenario(event.dataSize, emit);
          break;
        case ScenarioType.cascadingUpdates:
          await _runCascadingUpdatesScenario(event.dataSize, emit);
          break;
        case ScenarioType.highFrequency:
          await _runHighFrequencyScenario(event.dataSize, emit);
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

  // S01 - API Data Streaming
  Future<void> _runApiStreamingScenario(
      int dataSize, Emitter<BenchmarkState> emit) async {
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      isStreamingActive: true,
    ));

    final maxPages = (dataSize / 20).ceil();
    _currentPage = 1;

    _scenarioTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_currentPage > maxPages) {
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      add(StreamingTick());
      _currentPage++;
    });
  }

  Future<void> _onStreamingTick(
      StreamingTick event, Emitter<BenchmarkState> emit) async {
    try {
      UIPerformanceTracker.markStateUpdate(); // ZMIANA

      final newMovies = await apiClient.getPopularMovies(page: _currentPage);
      final allMovies = [...state.movies, ...newMovies];

      emit(state.copyWith(
        movies: allMovies,
        filteredMovies: allMovies,
        loadedCount: allMovies.length,
        progressCounter: _currentPage,
        statusText: 'Loading page $_currentPage...',
      ));
    } catch (e) {
      // Handle error but continue
    }
  }

  // S02 - Real-time Data Filtering
  Future<void> _runRealtimeFilteringScenario(
      int dataSize, Emitter<BenchmarkState> emit) async {
    // Load initial data
    final movies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
      currentFilterIndex: 0,
    ));

    // Start filtering cycle
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.currentFilterIndex >= _predefinedFilters.length * 5) {
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      add(FilteringTick());
    });
  }

  void _onFilteringTick(FilteringTick event, Emitter<BenchmarkState> emit) {
    final filterIndex = state.currentFilterIndex % _predefinedFilters.length;
    final filter = _predefinedFilters[filterIndex];

    UIPerformanceTracker.markStateUpdate(); // ZMIANA

    var filtered = state.movies.where((movie) {
      bool matchesYear = filter['year'] == null ||
          movie.releaseDate.startsWith(filter['year'].toString());
      bool matchesGenre =
          filter['genre'] == null || movie.genreIds.contains(filter['genre']);
      bool matchesRating =
          filter['rating'] == null || movie.voteAverage >= filter['rating'];

      return matchesYear && matchesGenre && matchesRating;
    }).toList();

    emit(state.copyWith(
      filteredMovies: filtered,
      currentFilterIndex: state.currentFilterIndex + 1,
      statusText:
          'Filter ${state.currentFilterIndex + 1}: ${filtered.length} movies',
    ));
  }

  // S03 - Memory Pressure Simulation
  Future<void> _runMemoryPressureScenario(
      int dataSize, Emitter<BenchmarkState> emit) async {
    final movies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
    ));

    int cycleCount = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      cycleCount++;

      if (cycleCount > 133) {
        // ~20 seconds
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      if (cycleCount % 20 == 0) {
        add(SimplifyMoviesData());
      } else {
        add(EnrichMoviesData());
      }
    });
  }

  void _onEnrichMoviesData(
      EnrichMoviesData event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA

    final enriched = state.movies
        .map((movie) => EnrichedMovie(
              baseMovie: movie,
              cast: List.generate(10, (i) => 'Actor ${movie.id}_$i'),
              crew: List.generate(15, (i) => 'Crew ${movie.id}_$i'),
              reviews: List.generate(
                  5,
                  (i) => MovieReview(
                        author: 'User${movie.id}_$i',
                        content:
                            'Review content for ${movie.title} - review number $i' *
                                10,
                        rating: _random.nextDouble() * 10,
                      )),
              watchProgress: _random.nextDouble(),
              isFavorite: _random.nextBool(),
              isInWatchlist: _random.nextBool(),
            ))
        .toList();

    emit(state.copyWith(
      enrichedMovies: enriched,
      statusText: 'Enriched: ${enriched.length} movies with extra data',
    ));
  }

  void _onSimplifyMoviesData(
      SimplifyMoviesData event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      enrichedMovies: [],
      statusText: 'Simplified: Removed extra data',
    ));
  }

  // S04 - Cascading State Updates
  Future<void> _runCascadingUpdatesScenario(
      int dataSize, Emitter<BenchmarkState> emit) async {
    final movies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
    ));

    int updateCycle = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      updateCycle++;

      if (updateCycle > 100) {
        // ~30 seconds
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      add(CascadingUpdateTick());
    });
  }

  void _onCascadingUpdateTick(
      CascadingUpdateTick event, Emitter<BenchmarkState> emit) {
    // 1. Global theme change
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(isAccessibilityMode: !state.isAccessibilityMode));

    // 2. View mode change
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      viewMode: state.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
    ));

    // 3. Toggle favorites on random movies
    final randomMovies = List.generate(
            10, (i) => state.movies[_random.nextInt(state.movies.length)].id)
        .toSet();
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(expandedMovies: randomMovies));

    // 4. Update filter
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    final randomGenre = [28, 35, 18, 27, 16][_random.nextInt(5)];
    final filtered =
        state.movies.where((m) => m.genreIds.contains(randomGenre)).toList();

    emit(state.copyWith(
      filteredMovies: filtered,
      statusText:
          'Cascade ${state.progressCounter + 1}: ${filtered.length} movies',
      progressCounter: state.progressCounter + 1,
    ));
  }

  // S05 - High-Frequency Updates
  Future<void> _runHighFrequencyScenario(
      int dataSize, Emitter<BenchmarkState> emit) async {
    final movies = await apiClient.loadAllMovies(
        totalItems: min(dataSize, 1000)); // Limit for performance

    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
      multiCounters: List.filled(20, 0),
      loadingStates: List.filled(20, false),
    ));

    int frameCount = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // 60 FPS
      frameCount++;

      if (frameCount > 1200) {
        // 20 seconds at 60 FPS
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      add(HighFrequencyTick());
    });
  }

  void _onHighFrequencyTick(
      HighFrequencyTick event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA

    // Update multiple reactive variables
    final newCounters = state.multiCounters.map((c) => c + 1).toList();
    final newLoadingStates =
        state.loadingStates.map((s) => _random.nextBool()).toList();

    emit(state.copyWith(
      progressCounter: state.progressCounter + 1,
      statusText: 'Frame ${state.progressCounter + 1}',
      multiCounters: newCounters,
      loadingStates: newLoadingStates,
    ));
  }

  void _onMemoryPressureTick(
      MemoryPressureTick event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      progressCounter: state.progressCounter + 1,
      statusText: 'Memory pressure cycle ${state.progressCounter + 1}',
    ));
  }

  // Zachowane metody z dodanym state update tracking
  Future<void> _onLoadMoreMovies(
      LoadMoreMovies event, Emitter<BenchmarkState> emit) async {
    if (isLoadingMore || state.loadedCount >= state.dataSize) return;

    isLoadingMore = true;
    _currentPage++;

    try {
      final newMovies = await apiClient.getPopularMovies(page: _currentPage);
      final moviesToAdd =
          newMovies.take(state.dataSize - state.loadedCount).toList();
      final allMovies = [...state.movies, ...moviesToAdd];

      UIPerformanceTracker.markStateUpdate(); // ZMIANA
      emit(state.copyWith(
        movies: allMovies,
        filteredMovies: allMovies,
        loadedCount: allMovies.length,
      ));

      if (allMovies.length >= state.dataSize) {
        emit(state.copyWith(isAutoScrolling: false));
        add(BenchmarkCompleted());
      }
    } finally {
      isLoadingMore = false;
    }
  }

  void _onFilterMovies(FilterMovies event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    final filtered = state.movies
        .where(
            (movie) => movie.genreIds.any((id) => event.genreIds.contains(id)))
        .toList();
    emit(state.copyWith(filteredMovies: filtered));
  }

  void _onSortMovies(SortMovies event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    final sorted = [...state.filteredMovies];
    if (event.byReleaseDate) {
      sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else {
      sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }
    emit(state.copyWith(filteredMovies: sorted));
  }

  void _onToggleViewMode(ToggleViewMode event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(
      viewMode: state.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
    ));
  }

  void _onToggleAccessibilityMode(
      ToggleAccessibilityMode event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    emit(state.copyWith(isAccessibilityMode: !state.isAccessibilityMode));
  }

  void _onToggleMovieExpanded(
      ToggleMovieExpanded event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markStateUpdate(); // ZMIANA
    final expandedMovies = {...state.expandedMovies};
    if (expandedMovies.contains(event.movieId)) {
      expandedMovies.remove(event.movieId);
    } else {
      expandedMovies.add(event.movieId);
    }
    emit(state.copyWith(expandedMovies: expandedMovies));
  }

  void _onBenchmarkCompleted(
      BenchmarkCompleted event, Emitter<BenchmarkState> emit) {
    _scenarioTimer?.cancel();
    emit(state.copyWith(
      status: BenchmarkStatus.completed,
      endTime: DateTime.now(),
      isAutoScrolling: false,
      isStreamingActive: false,
    ));
    _completeTestWithReports();
  }

  void _completeTestWithReports() {
    MemoryMonitor.stopMonitoring();
    UIPerformanceTracker.stopTracking(); // ZMIANA

    final memoryReport = MemoryMonitor.generateReport();
    final upmReport = UIPerformanceTracker.generateReport(); // ZMIANA

    print('=== BLoC Memory Report for ${state.scenarioType} ===');
    print(memoryReport.toFormattedString());
    print('=== BLoC UMP Report for ${state.scenarioType} ==='); // ZMIANA
    print(upmReport.toFormattedString());
  }

  @override
  Future<void> close() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    return super.close();
  }
}
