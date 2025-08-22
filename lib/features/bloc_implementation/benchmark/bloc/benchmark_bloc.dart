import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/memory_stress_config.dart';
import 'package:moviedb_benchmark/core/utils/ui_stress_config.dart';
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
    on<CreateComplexObjects>(_onCreateComplexObjects);
    on<AllocateLargeLists>(_onAllocateLargeLists);
    on<PerformStringOperations>(_onPerformStringOperations);
    on<CreateLargeMaps>(_onCreateLargeMaps);
    on<CleanupOldStates>(_onCleanupOldStates);

    // S03 - UI Updates
    on<UpdateMovieLikeStatus>(_onUpdateMovieLikeStatus);
    on<UpdateMovieViewCount>(_onUpdateMovieViewCount);
    on<UpdateMovieProgress>(_onUpdateMovieProgress);
    on<UpdateMovieDownloadStatus>(_onUpdateMovieDownloadStatus);
    on<UpdateMovieRating>(_onUpdateMovieRating);
    on<HeavySortOperation>(_onHeavySortOperation);
    on<HeavyFilterOperation>(_onHeavyFilterOperation);

    on<BenchmarkCompleted>(_onBenchmarkCompleted);
    on<IncrementFrameCounter>(_onIncrementFrameCounter);
  }

  void _onIncrementFrameCounter(
      IncrementFrameCounter event, Emitter<BenchmarkState> emit) {
    emit(state.copyWith(frameCounter: state.frameCounter + 1));
  }

  Future<void> _onStartBenchmark(
      StartBenchmark event, Emitter<BenchmarkState> emit) async {
    UIPerformanceTracker.markAction();

    emit(state.copyWith(
      status: BenchmarkStatus.loading,
      scenarioType: event.scenarioType,
      dataSize: event.dataSize,
      stressLevel: event.stressLevel, // DODANE
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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

    final newProcessingState = state.processingState.copyWith(
      processingStep: 5,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(processingState: newProcessingState));
  }

  // S02 - Memory State History Implementation
  Future<void> _runMemoryStateHistory() async {
    final stressLevel = state.stressLevel ?? TestStressLevel.medium;
    final config = MemoryStressConfig.getConfig(stressLevel);

    int cycle = 0;
    const testDurationMs = 60000; // 60 sekund
    final testStartTime = DateTime.now();

    _scenarioTimer = Timer.periodic(config.operationInterval, (timer) {
      if (DateTime.now().difference(testStartTime).inMilliseconds >=
          testDurationMs) {
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      // Memory-intensive operations cycle
      for (int i = 0; i < config.deepCopyOperations; i++) {
        add(ApplyFilterConfiguration(
            _filterTypes[cycle % _filterTypes.length], cycle));
        add(ApplySortConfiguration(_sortTypes[cycle % _sortTypes.length]));
        add(ApplyGroupConfiguration(_groupTypes[cycle % _groupTypes.length]));
        add(ApplyPaginationConfiguration(cycle % 10));
      }

      // Memory stress operations
      add(CreateComplexObjects(config.complexObjectsPerCycle));
      add(AllocateLargeLists(config.largeListAllocations));
      add(PerformStringOperations(config.stringConcatenations));
      add(CreateLargeMaps(config.mapCreations));

      // Memory cleanup operations (simulate GC pressure)
      if (cycle % 5 == 4) {
        add(CleanupOldStates(config.stateRetentionPercent));
      }

      // Backward operations (rollback every 8th cycle)
      if (cycle % 8 == 7) {
        add(UndoToStep(max(0, state.currentHistoryIndex - 4)));
      }

      cycle++;
    });
  }

  void _onCreateComplexObjects(
      CreateComplexObjects event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    // Create complex nested objects to stress memory allocation
    final complexData = <String, dynamic>{};
    for (int i = 0; i < event.count; i++) {
      final movieCopy = state.movies.isNotEmpty
          ? state.movies[i % state.movies.length]
          : null;

      if (movieCopy != null) {
        // Create deep copies with additional data
        complexData['object_$i'] = {
          'movie': movieCopy,
          'metadata': _createMetadata(i),
          'analytics': _createAnalyticsData(i),
          'cache': _createCacheData(i),
          'timestamp': DateTime.now(),
        };
      }
    }

    final currentState = state.processingState;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['complexObjects'] = event.count.toDouble();
    newMetrics['memoryPressure'] = (newMetrics['memoryPressure'] ?? 0) + 1;

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [
      ...state.operationLog,
      'Created ${event.count} complex objects'
    ];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onAllocateLargeLists(
      AllocateLargeLists event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    // Allocate large lists to stress memory
    final largeLists = <List<dynamic>>[];
    for (int i = 0; i < event.count; i++) {
      final largeList = List.generate(
          1000,
          (index) => {
                'id': index,
                'data': 'Item $index with large data payload: ${'x' * 100}',
                'nested': List.generate(10, (j) => 'nested_$j'),
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
      largeLists.add(largeList);
    }

    final currentState = state.processingState;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['largeListsAllocated'] = event.count.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [
      ...state.operationLog,
      'Allocated ${event.count} large lists'
    ];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onPerformStringOperations(
      PerformStringOperations event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    // Perform memory-intensive string operations
    String result = '';
    for (int i = 0; i < event.count; i++) {
      result += 'String operation $i with movie data: ';
      if (state.movies.isNotEmpty) {
        final movie = state.movies[i % state.movies.length];
        result +=
            '${movie.title} - ${movie.overview.substring(0, min(50, movie.overview.length))}';
      }
      result += '\n';
    }

    final currentState = state.processingState;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['stringOperations'] = event.count.toDouble();
    newMetrics['stringLength'] = result.length.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [
      ...state.operationLog,
      'Performed ${event.count} string operations'
    ];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onCreateLargeMaps(CreateLargeMaps event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    // Create large maps to stress memory allocation
    final largeMaps = <Map<String, dynamic>>[];
    for (int i = 0; i < event.count; i++) {
      final largeMap = <String, dynamic>{};
      for (int j = 0; j < 100; j++) {
        largeMap['key_${i}_$j'] = {
          'value': 'Large value $j with repeated data: ${'data' * 25}',
          'metadata': List.generate(5, (k) => 'meta_$k'),
          'timestamp': DateTime.now(),
        };
      }
      largeMaps.add(largeMap);
    }

    final currentState = state.processingState;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['largeMapsCreated'] = event.count.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.stateHistory, newState];
    final newLog = [...state.operationLog, 'Created ${event.count} large maps'];

    emit(state.copyWith(
      processingState: newState,
      stateHistory: newHistory,
      currentHistoryIndex: newHistory.length - 1,
      operationLog: newLog,
    ));
  }

  void _onCleanupOldStates(
      CleanupOldStates event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    // Clean up old states to simulate memory management
    final currentHistory = state.stateHistory;
    final retainCount =
        (currentHistory.length * event.retentionPercent).round();
    final newHistory = currentHistory.length > retainCount
        ? currentHistory.sublist(currentHistory.length - retainCount)
        : currentHistory;

    final newLog = [
      ...state.operationLog,
      'Cleaned up ${currentHistory.length - newHistory.length} old states'
    ];

    emit(state.copyWith(
      stateHistory: newHistory,
      currentHistoryIndex:
          min(state.currentHistoryIndex, newHistory.length - 1),
      operationLog: newLog,
    ));
  }

// Helper methods for complex object creation:
  Map<String, dynamic> _createMetadata(int index) {
    return {
      'id': index,
      'created': DateTime.now(),
      'tags': List.generate(10, (i) => 'tag_$i'),
      'properties': {
        'size': index * 1.5,
        'weight': index * 2.3,
        'category': 'category_${index % 5}',
      },
    };
  }

  Map<String, dynamic> _createAnalyticsData(int index) {
    return {
      'views': index * 100,
      'likes': index * 10,
      'shares': index * 5,
      'comments': List.generate(index % 20, (i) => 'Comment $i with data'),
      'metrics': {
        'engagement': index * 0.1,
        'retention': index * 0.05,
        'conversion': index * 0.02,
      },
    };
  }

  Map<String, dynamic> _createCacheData(int index) {
    return {
      'cached_at': DateTime.now(),
      'expires_at': DateTime.now().add(Duration(hours: index % 24)),
      'data': List.generate(50, (i) => 'cache_data_${index}_$i'),
      'metadata': {
        'size_bytes': index * 1024,
        'compression': 'gzip',
        'version': '1.0.$index',
      },
    };
  }

  void _onApplyFilterConfiguration(
      ApplyFilterConfiguration event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();

    if (state.currentHistoryIndex > 0) {
      add(UndoToStep(state.currentHistoryIndex - 1));
    }
  }

  // S03 - UI Granular Updates Implementation
  // ZMIEŃ całą metodę _runUiGranularUpdates:
  Future<void> _runUiGranularUpdates() async {
    final stressLevel = state.stressLevel ?? TestStressLevel.medium;
    final config = UIStressConfig.getConfig(stressLevel);

    // Initialize UI states for all movies
    final initialStates = <int, UIElementState>{};
    for (final movie in state.movies) {
      initialStates[movie.id] = UIElementState(movieId: movie.id);
    }

    emit(state.copyWith(uiElementStates: initialStates));

    // ZMIENIONE - użyj czasu zamiast frameCounter
    const testDurationMs = 30000; // 30 sekund
    final testStartTime = DateTime.now();

    _scenarioTimer = Timer.periodic(config.timerInterval, (timer) {
      // ZMIENIONE - sprawdź czas zamiast frameCounter
      if (DateTime.now().difference(testStartTime).inMilliseconds >=
          testDurationMs) {
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      // DODANE - jeden markAction na początku iteracji
      UIPerformanceTracker.markAction();

      final movieCount = state.movies.length;
      final likeUpdates =
          _getRandomMovieIds(movieCount, config.likeUpdatePercent);
      final viewUpdates =
          _getRandomMovieIds(movieCount, config.viewUpdatePercent);
      final progressUpdates =
          _getRandomMovieIds(movieCount, config.progressUpdatePercent);
      final downloadUpdates =
          _getRandomMovieIds(movieCount, config.downloadUpdatePercent);
      final ratingUpdates =
          _getRandomMovieIds(movieCount, config.ratingUpdatePercent);

      add(UpdateMovieLikeStatus(likeUpdates));
      add(UpdateMovieViewCount(viewUpdates));
      add(UpdateMovieProgress(progressUpdates));
      add(UpdateMovieDownloadStatus(downloadUpdates));
      add(UpdateMovieRating(ratingUpdates));

      if (state.frameCounter % config.heavySortFrequency == 0) {
        add(HeavySortOperation(config.mathIterations));
      }

      if (state.frameCounter % config.heavyFilterFrequency == 0) {
        add(HeavyFilterOperation(config.mathIterations));
      }

      // DODANE - increment frameCounter raz na iterację
      add(IncrementFrameCounter());
    });
  }

  void _onUpdateMovieLikeStatus(
      UpdateMovieLikeStatus event, Emitter<BenchmarkState> emit) {
    final config =
        UIStressConfig.getConfig(state.stressLevel ?? TestStressLevel.medium);
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        double lightCalculation = 0;
        for (int i = 0; i < config.mathIterations; i++) {
          lightCalculation += math.sin(movieId * i / 100.0);
        }

        newStates[movieId] = currentState.copyWith(
          isLiked: !currentState.isLiked,
          rating:
              (currentState.rating + lightCalculation * 0.01).clamp(0.0, 10.0),
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(
      uiElementStates: newStates,
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieViewCount(
      UpdateMovieViewCount event, Emitter<BenchmarkState> emit) {
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
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieProgress(
      UpdateMovieProgress event, Emitter<BenchmarkState> emit) {
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
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieDownloadStatus(
      UpdateMovieDownloadStatus event, Emitter<BenchmarkState> emit) {
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
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onUpdateMovieRating(
      UpdateMovieRating event, Emitter<BenchmarkState> emit) {
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
      lastUpdatedMovieIds: event.movieIds,
    ));
  }

  void _onHeavySortOperation(
      HeavySortOperation event, Emitter<BenchmarkState> emit) {
    final sorted = [...state.movies];
    sorted.sort((a, b) {
      double aWeight = a.voteAverage;
      double bWeight = b.voteAverage;

      for (int k = 0; k < event.iterations; k++) {
        aWeight += math.sin(a.id * k / 50.0) * 0.001;
        bWeight += math.sin(b.id * k / 50.0) * 0.001;
      }

      return bWeight.compareTo(aWeight);
    });

    emit(state.copyWith(
      movies: sorted,
    ));
  }

  void _onHeavyFilterOperation(
      HeavyFilterOperation event, Emitter<BenchmarkState> emit) {
    final filtered = <Movie>[];
    for (final movie in state.movies) {
      double complexity = 0;
      for (int i = 0; i < event.iterations * 5; i++) {
        complexity += math.cos(movie.id * i / 100.0);
      }

      if (complexity > -event.iterations * 2) {
        filtered.add(movie);
      }
    }

    final newProcessingState = state.processingState.copyWith(
      filteredMovies: filtered,
      processingStep: state.processingState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      processingState: newProcessingState,
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
    final uiReport = UIPerformanceTracker.generateReport(); // ZMIENIONE

    print('=== BLoC Memory Report for ${state.scenarioType} ===');
    print(memoryReport.toFormattedString());
    print(
        '=== BLoC UI Performance Report for ${state.scenarioType} ==='); // ZMIENIONE
    print(uiReport.toFormattedString()); // ZMIENIONE
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
