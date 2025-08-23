import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'package:moviedb_benchmark/core/models/processing_state.dart';
import 'package:moviedb_benchmark/core/models/ui_element_state.dart';
import 'package:moviedb_benchmark/core/models/cpu_processing_state.dart';
import 'benchmark_event.dart';
import 'benchmark_state.dart';

class BenchmarkBloc extends Bloc<BenchmarkEvent, BenchmarkState> {
  final TmdbApiClient apiClient;
  Timer? _scenarioTimer;
  final Random _random = Random(42);

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

    // S01
    on<ExecuteProcessingCycle>(_onExecuteProcessingCycle);

    // S02
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

    // S03
    on<PerformMassiveUIUpdates>(_onPerformMassiveUIUpdates);
    on<PerformAnimationUpdates>(_onPerformAnimationUpdates);
    on<PerformConditionalUpdates>(_onPerformConditionalUpdates);
    on<PerformBatchUpdate>(_onPerformBatchUpdate);
    on<PerformCascadingUpdates>(_onPerformCascadingUpdates);
    on<PerformMemoryPressureUpdate>(_onPerformMemoryPressureUpdate);
    on<UpdateMovieLikes>(_onUpdateMovieLikes);
    on<UpdateMovieProgressBatch>(_onUpdateMovieProgressBatch);
    on<UpdateMovieRatingsBatch>(_onUpdateMovieRatingsBatch);
    on<UpdateMovieDownloadsBatch>(_onUpdateMovieDownloadsBatch);
    on<UpdateMovieViewsBatch>(_onUpdateMovieViewsBatch);
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
      startTime: DateTime.now(),
    ));

    MemoryMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
    UIPerformanceTracker.startTracking();

    try {
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

  // S01
  Future<void> _runCpuProcessingPipeline() async {
    int cycle = 0;
    const maxCycles = 600;

    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (cycle >= maxCycles) {
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      add(ExecuteProcessingCycle(cycle));
      cycle++;
    });
  }

  void _onExecuteProcessingCycle(
      ExecuteProcessingCycle event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    final movies = state.movies;
    if (movies.isEmpty) return;

    final filterCriteria = ['genre', 'year', 'rating'][event.cycleNumber % 3];
    final filteredMovies =
        _performIntensiveFiltering(movies, filterCriteria, event.cycleNumber);

    final metrics = _calculateComplexMetrics(filteredMovies);

    final sortedMovies =
        _performComplexSorting([...filteredMovies], event.cycleNumber);

    final groupingCriteria =
        ['decade', 'genre', 'rating_range'][event.cycleNumber % 3];
    final groupedMovies =
        _performComplexGrouping(sortedMovies, groupingCriteria);

    final newCpuState = state.cpuProcessingState.copyWith(
      rawMovies: movies,
      filteredMovies: filteredMovies,
      sortedMovies: sortedMovies,
      groupedMovies: groupedMovies,
      calculatedMetrics: metrics,
      currentGenre: _getFilterValue(filterCriteria, event.cycleNumber),
      currentSortType: _getSortType(event.cycleNumber),
      currentGroupType: groupingCriteria,
      processingStep: 5,
      cycleCount: event.cycleNumber,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(cpuProcessingState: newCpuState));
  }

  List<Movie> _performIntensiveFiltering(
      List<Movie> movies, String criteria, int cycle) {
    return movies.where((movie) {
      double complexity = 0;
      for (int i = 0; i < 50; i++) {
        complexity += math.sin(movie.id * i * cycle / 100.0) *
            math.cos(movie.voteAverage * i / 10.0);
      }

      switch (criteria) {
        case 'genre':
          final targetGenreId = _getGenreIdForCycle(cycle);
          return movie.genreIds.contains(targetGenreId) && complexity > -25;
        case 'year':
          final targetYear = 2000 + (cycle % 25);
          return movie.releaseDate.startsWith(targetYear.toString()) &&
              complexity > -25;
        case 'rating':
          final minRating = 5.0 + (cycle % 4);
          return movie.voteAverage >= minRating && complexity > -25;
        default:
          return complexity > -25;
      }
    }).toList();
  }

  Map<String, double> _calculateComplexMetrics(List<Movie> movies) {
    if (movies.isEmpty) return {};

    double sum = 0;
    double sumSquares = 0;
    double weightedSum = 0;

    for (final movie in movies) {
      for (int i = 0; i < 20; i++) {
        final weight = math.exp(movie.voteAverage * i / 100.0);
        weightedSum += movie.voteAverage * weight;
        sum += movie.voteAverage;
        sumSquares += movie.voteAverage * movie.voteAverage;
      }
    }

    final mean = sum / (movies.length * 20);
    final variance = (sumSquares / (movies.length * 20)) - (mean * mean);
    final weightedMean = weightedSum / (movies.length * 20);

    return {
      'averageRating': mean,
      'variance': variance,
      'weightedAverage': weightedMean,
      'totalMovies': movies.length.toDouble(),
      'complexityIndex': weightedSum / 1000,
    };
  }

  List<Movie> _performComplexSorting(List<Movie> movies, int cycle) {
    movies.sort((a, b) {
      double aWeight = a.voteAverage;
      double bWeight = b.voteAverage;

      for (int i = 0; i < 15; i++) {
        aWeight += math.sin(a.id * i * cycle / 200.0) * 0.001;
        bWeight += math.sin(b.id * i * cycle / 200.0) * 0.001;
        aWeight *= (1 + math.cos(i * cycle / 100.0) * 0.01);
        bWeight *= (1 + math.cos(i * cycle / 100.0) * 0.01);
      }

      return bWeight.compareTo(aWeight);
    });

    return movies;
  }

  Map<String, List<Movie>> _performComplexGrouping(
      List<Movie> movies, String criteria) {
    final groups = <String, List<Movie>>{};

    for (final movie in movies) {
      double complexity = 0;
      for (int i = 0; i < 10; i++) {
        complexity +=
            math.log(movie.id + i + 1) * math.sqrt(movie.voteAverage + 1);
      }

      String key;
      switch (criteria) {
        case 'decade':
          final year = int.tryParse(movie.releaseDate.split('-').first) ?? 2000;
          final decade = (year ~/ 10) * 10;
          key = '${decade}s (${complexity.toStringAsFixed(1)})';
          break;
        case 'genre':
          final genreId = movie.genreIds.isNotEmpty ? movie.genreIds.first : 0;
          final genreName = _getGenreForId(genreId);
          key = '$genreName (${complexity.toStringAsFixed(1)})';
          break;
        case 'rating_range':
          final rating = movie.voteAverage + (complexity * 0.01);
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

  int _getGenreIdForCycle(int cycle) {
    const genreIds = [28, 35, 18, 27, 10749, 878];
    return genreIds[cycle % genreIds.length];
  }

  String _getFilterValue(String criteria, int cycle) {
    switch (criteria) {
      case 'genre':
        return _getGenreForId(_getGenreIdForCycle(cycle));
      case 'year':
        return (2000 + (cycle % 25)).toString();
      case 'rating':
        return (5.0 + (cycle % 4)).toString();
      default:
        return '';
    }
  }

  String _getSortType(int cycle) {
    const types = ['complex_rating', 'weighted_date', 'enhanced_popularity'];
    return types[cycle % types.length];
  }

  String _getGenreForId(int genreId) {
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

  // S02
  Future<void> _runMemoryStateHistory() async {
    const operationInterval = Duration(milliseconds: 50);
    const complexObjectsPerCycle = 50;
    const deepCopyOperations = 10;
    const largeListAllocations = 30;
    const stringConcatenations = 600;
    const mapCreations = 15;
    const stateRetentionPercent = 0.4;

    int cycle = 0;
    const testDurationMs = 60000;
    final testStartTime = DateTime.now();

    _scenarioTimer = Timer.periodic(operationInterval, (timer) {
      if (DateTime.now().difference(testStartTime).inMilliseconds >=
          testDurationMs) {
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      for (int i = 0; i < deepCopyOperations; i++) {
        add(ApplyFilterConfiguration(
            _filterTypes[cycle % _filterTypes.length], cycle));
        add(ApplySortConfiguration(_sortTypes[cycle % _sortTypes.length]));
        add(ApplyGroupConfiguration(_groupTypes[cycle % _groupTypes.length]));
        add(ApplyPaginationConfiguration(cycle % 10));
      }

      add(const CreateComplexObjects(complexObjectsPerCycle));
      add(const AllocateLargeLists(largeListAllocations));
      add(const PerformStringOperations(stringConcatenations));
      add(const CreateLargeMaps(mapCreations));

      if (cycle % 5 == 4) {
        add(const CleanupOldStates(stateRetentionPercent));
      }

      if (cycle % 8 == 7) {
        add(UndoToStep(max(0, state.currentHistoryIndex - 4)));
      }

      cycle++;
    });
  }

  void _onCreateComplexObjects(
      CreateComplexObjects event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    final complexData = <String, dynamic>{};
    for (int i = 0; i < event.count; i++) {
      final movieCopy = state.movies.isNotEmpty
          ? state.movies[i % state.movies.length]
          : null;

      if (movieCopy != null) {
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

  // S03
  Future<void> _runUiGranularUpdates() async {
    // Identyczne parametry jak GetX
    const timerInterval = Duration(milliseconds: 8);
    const uiUpdatePercent = 0.60;
    const animationPercent = 0.40;
    const conditionalUpdatePercent = 0.50;
    const batchUpdateFrequency = 3;
    const cascadeUpdateFrequency = 7;
    const memoryPressureFrequency = 11;

    // Inicjalizacja rozszerzonych UI states
    final initialStates = <int, UIElementState>{};
    for (final movie in state.movies) {
      initialStates[movie.id] = UIElementState(
        movieId: movie.id,
        tags: List.generate(20, (i) => 'tag_${movie.id}_$i'),
        thumbnails: List.generate(10, (i) => 'thumb_${movie.id}_$i'),
        metadata: {
          'created': DateTime.now().millisecondsSinceEpoch,
          'category': 'category_${movie.id % 5}',
          'data': List.generate(50, (i) => 'data_${movie.id}_$i'),
        },
      );
    }

    emit(state.copyWith(uiElementStates: initialStates));

    const testDurationMs = 30000; // 30 sekund intensywnego testu
    final testStartTime = DateTime.now();
    int cycleCount = 0;

    _scenarioTimer = Timer.periodic(timerInterval, (timer) {
      if (DateTime.now().difference(testStartTime).inMilliseconds >=
          testDurationMs) {
        timer.cancel();
        add(BenchmarkCompleted());
        return;
      }

      // CORE UPDATES - każdy cykl
      add(const PerformMassiveUIUpdates(uiUpdatePercent));
      add(const PerformAnimationUpdates(animationPercent));
      add(const PerformConditionalUpdates(conditionalUpdatePercent));

      // INTENSIVE OPERATIONS - okresowo
      if (cycleCount % batchUpdateFrequency == 0) {
        add(PerformBatchUpdate());
      }

      if (cycleCount % cascadeUpdateFrequency == 0) {
        add(PerformCascadingUpdates());
      }

      if (cycleCount % memoryPressureFrequency == 0) {
        add(PerformMemoryPressureUpdate());
      }

      add(IncrementFrameCounter());
      cycleCount++;
    });
  }

  void _onPerformMassiveUIUpdates(
      PerformMassiveUIUpdates event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    final movieIds = _getRandomMovieIds(state.movies.length, event.percent);

    // Micro-updates: każde właściwość osobno dla maksymalnej granularności
    final likeUpdates = movieIds.take(movieIds.length ~/ 5).toList();
    final progressUpdates =
        movieIds.skip(movieIds.length ~/ 5).take(movieIds.length ~/ 5).toList();
    final ratingUpdates = movieIds
        .skip((movieIds.length * 2) ~/ 5)
        .take(movieIds.length ~/ 5)
        .toList();
    final downloadUpdates = movieIds
        .skip((movieIds.length * 3) ~/ 5)
        .take(movieIds.length ~/ 5)
        .toList();
    final viewUpdates = movieIds.skip((movieIds.length * 4) ~/ 5).toList();

    // Każda aktualizacja to osobny event
    add(UpdateMovieLikes(likeUpdates));
    add(UpdateMovieProgressBatch(progressUpdates));
    add(UpdateMovieRatingsBatch(ratingUpdates));
    add(UpdateMovieDownloadsBatch(downloadUpdates));
    add(UpdateMovieViewsBatch(viewUpdates));
  }

  void _onPerformAnimationUpdates(
      PerformAnimationUpdates event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    final animatedMovieIds =
        _getRandomMovieIds(state.movies.length, event.percent);
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in animatedMovieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        // Identyczna logika animacji jak GetX
        final newAnimationProgress =
            (currentState.animationProgress + 0.05) % 1.0;
        final newOpacity = 0.3 +
            (0.7 * (0.5 + 0.5 * math.sin(newAnimationProgress * 2 * math.pi)));
        final newProgress =
            0.5 + 0.5 * math.sin(newAnimationProgress * 4 * math.pi);

        newStates[movieId] = currentState.copyWith(
          isAnimating: true,
          animationProgress: newAnimationProgress,
          opacity: newOpacity,
          progress: newProgress,
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(uiElementStates: newStates));
  }

  void _onPerformConditionalUpdates(
      PerformConditionalUpdates event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    final movieIds = _getRandomMovieIds(state.movies.length, event.percent);
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        // Identyczna logika conditional updates jak GetX
        newStates[movieId] = currentState.copyWith(
          isFeatured: !currentState.isFeatured,
          isHighlighted: currentState.popularityScore > 50,
          isWatched: currentState.progress >= 1.0,
          popularityScore:
              (currentState.popularityScore + _random.nextInt(20) - 10)
                  .clamp(0, 100),
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state.copyWith(uiElementStates: newStates));
  }

  void _onPerformBatchUpdate(
      PerformBatchUpdate event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    final newStates = <int, UIElementState>{};

    // Update wszystkich filmów jednocześnie - identyczna logika jak GetX
    for (final movie in state.movies) {
      final currentState = state.uiElementStates[movie.id];
      if (currentState != null) {
        newStates[movie.id] = currentState.copyWith(
          viewCount: currentState.viewCount + _random.nextInt(5),
          popularityScore: _random.nextInt(100),
          tags: List.generate(25, (i) => 'batch_tag_${movie.id}_$i'),
          metadata: {
            ...currentState.metadata,
            'batchUpdate': DateTime.now().millisecondsSinceEpoch,
            'cycle': state.frameCounter,
          },
          lastUpdated: DateTime.now(),
        );
      }
    }

    emit(state
        .copyWith(uiElementStates: {...state.uiElementStates, ...newStates}));
  }

  void _onPerformCascadingUpdates(
      PerformCascadingUpdates event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    if (state.movies.isNotEmpty) {
      final primaryMovieId = state.movies[0].id;
      final primaryState = state.uiElementStates[primaryMovieId];

      if (primaryState != null) {
        // Update primary movie
        final newPrimaryState = primaryState.copyWith(
          isLiked: !primaryState.isLiked,
          isFeatured: true,
          popularityScore: 100,
        );

        // Cascade effect na related movies (first 200)
        final relatedMovies = state.movies.skip(1).take(200);
        final newStates = Map<int, UIElementState>.from(state.uiElementStates);
        newStates[primaryMovieId] = newPrimaryState;

        for (final movie in relatedMovies) {
          final currentState = newStates[movie.id];
          if (currentState != null) {
            newStates[movie.id] = currentState.copyWith(
              isHighlighted: newPrimaryState.isLiked,
              opacity: newPrimaryState.isLiked ? 1.0 : 0.7,
              popularityScore: (currentState.popularityScore +
                      (newPrimaryState.isLiked ? 10 : -5))
                  .clamp(0, 100),
            );
          }
        }

        emit(state.copyWith(uiElementStates: newStates));

        // Second cascade wave po 16ms
        Timer(const Duration(milliseconds: 16), () {
          final secondWaveMovies = state.movies.skip(201).take(300);
          final secondWaveStates =
              Map<int, UIElementState>.from(state.uiElementStates);

          for (final movie in secondWaveMovies) {
            final currentState = secondWaveStates[movie.id];
            if (currentState != null) {
              secondWaveStates[movie.id] = currentState.copyWith(
                isFeatured:
                    newPrimaryState.isLiked && currentState.rating >= 7.0,
                isWatched: newPrimaryState.isLiked,
              );
            }
          }

          emit(state.copyWith(uiElementStates: secondWaveStates));
        });
      }
    }
  }

  void _onPerformMemoryPressureUpdate(
      PerformMemoryPressureUpdate event, Emitter<BenchmarkState> emit) {
    UIPerformanceTracker.markAction();

    final heavyStates = <int, UIElementState>{};
    final targetMovies = state.movies.take(500); // 500 filmów z heavy data

    for (final movie in targetMovies) {
      final currentState = state.uiElementStates[movie.id];
      if (currentState != null) {
        // Identyczna logika heavy objects jak GetX
        heavyStates[movie.id] = currentState.copyWith(
          tags: List.generate(100, (i) => 'heavy_tag_${movie.id}_$i'),
          thumbnails: List.generate(50, (i) => 'heavy_thumb_${movie.id}_$i'),
          metadata: {
            'heavyData': List.generate(200, (i) => 'heavy_data_${movie.id}_$i'),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'cycle': state.frameCounter,
            'randomData': List.generate(100, (i) => _random.nextDouble()),
          },
          isLiked: !currentState.isLiked,
          progress: _random.nextDouble(),
          rating: _random.nextDouble() * 10,
          lastUpdated: DateTime.now(),
        );
      }
    }

    // Batch emission - może powodować memory spike + UI freeze
    emit(state
        .copyWith(uiElementStates: {...state.uiElementStates, ...heavyStates}));
  }

  // Helper event handlers
  void _onUpdateMovieLikes(
      UpdateMovieLikes event, Emitter<BenchmarkState> emit) {
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          isLiked: !currentState.isLiked,
          popularityScore:
              currentState.popularityScore + (currentState.isLiked ? -1 : 1),
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }

    emit(state.copyWith(uiElementStates: newStates));
  }

  void _onUpdateMovieProgressBatch(
      UpdateMovieProgressBatch event, Emitter<BenchmarkState> emit) {
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        final newProgress = (currentState.progress + 0.05).clamp(0.0, 1.0);
        newStates[movieId] = currentState.copyWith(
          progress: newProgress,
          isWatched: newProgress >= 1.0,
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }

    emit(state.copyWith(uiElementStates: newStates));
  }

  void _onUpdateMovieRatingsBatch(
      UpdateMovieRatingsBatch event, Emitter<BenchmarkState> emit) {
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        final newRating = (currentState.rating + 0.5).clamp(0.0, 10.0);
        newStates[movieId] = currentState.copyWith(
          rating: newRating,
          isFeatured: newRating >= 8.0,
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }

    emit(state.copyWith(uiElementStates: newStates));
  }

  void _onUpdateMovieDownloadsBatch(
      UpdateMovieDownloadsBatch event, Emitter<BenchmarkState> emit) {
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          isDownloading: !currentState.isDownloading,
          opacity: currentState.isDownloading ? 1.0 : 0.8,
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }

    emit(state.copyWith(uiElementStates: newStates));
  }

  void _onUpdateMovieViewsBatch(
      UpdateMovieViewsBatch event, Emitter<BenchmarkState> emit) {
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        final newViewCount = currentState.viewCount + 1;
        newStates[movieId] = currentState.copyWith(
          viewCount: newViewCount,
          popularityScore: (currentState.popularityScore + (newViewCount ~/ 10))
              .clamp(0, 100),
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }

    emit(state.copyWith(uiElementStates: newStates));
  }

  void _onUpdateMovieLikeStatus(
      UpdateMovieLikeStatus event, Emitter<BenchmarkState> emit) {
    const mathIterations = 15;
    final newStates = Map<int, UIElementState>.from(state.uiElementStates);

    for (final movieId in event.movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        double lightCalculation = 0;
        for (int i = 0; i < mathIterations; i++) {
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

    emit(state.copyWith(movies: sorted));
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

    emit(state.copyWith(processingState: newProcessingState));
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
    final uiReport = UIPerformanceTracker.generateReport();

    print('=== BLoC Memory Report for ${state.scenarioType} ===');
    print(memoryReport.toFormattedString());
    print('=== BLoC UI Performance Report for ${state.scenarioType} ===');
    print(uiReport.toFormattedString());
  }

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

  @override
  Future<void> close() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    return super.close();
  }
}
