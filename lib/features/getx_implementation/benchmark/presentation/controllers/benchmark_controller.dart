import 'dart:async';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/models/processing_state.dart';
import 'package:moviedb_benchmark/core/models/ui_element_state.dart';
import 'package:moviedb_benchmark/core/models/cpu_processing_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';

class BenchmarkController extends GetxController {
  final TmdbApiClient apiClient = Get.put(TmdbApiClient());

  final status = BenchmarkStatus.initial.obs;
  final scenarioType = ScenarioType.cpuProcessingPipeline.obs;
  final movies = <Movie>[].obs;
  final error = Rx<String?>(null);
  final loadedCount = 0.obs;

  // S01
  final cpuProcessingState = CpuProcessingState().obs;

  // S02
  final processingState = ProcessingState().obs;
  final currentProcessingCycle = 0.obs;
  final genreRotation = <String>[].obs;
  final stateHistory = <ProcessingState>[].obs;
  final currentHistoryIndex = 0.obs;
  final operationLog = <String>[].obs;

  // S03
  final uiElementStates = <int, UIElementState>{}.obs;
  final frameCounter = 0.obs;
  final lastUpdatedMovieIds = <int>[].obs;

  int dataSize = 0;
  DateTime? startTime;
  DateTime? endTime;
  Timer? _scenarioTimer;
  final math.Random _random = math.Random(42);

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

  @override
  void onClose() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    super.onClose();
  }

  void startBenchmark(ScenarioType scenario, int size) async {
    UIPerformanceTracker.markAction();
    scenarioType.value = scenario;
    dataSize = size;
    startTime = DateTime.now();
    status.value = BenchmarkStatus.loading;

    MemoryMonitor.stopMonitoring();
    MemoryMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
    UIPerformanceTracker.startTracking();

    try {
      final loadedMovies = await apiClient.loadAllMovies(totalItems: size);

      UIPerformanceTracker.markAction();
      movies.value = loadedMovies;
      UIPerformanceTracker.markAction();
      loadedCount.value = loadedMovies.length;
      UIPerformanceTracker.markAction();
      genreRotation.value = _genreNames;
      UIPerformanceTracker.markAction();
      status.value = BenchmarkStatus.running;

      switch (scenario) {
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
      UIPerformanceTracker.markAction();
      status.value = BenchmarkStatus.error;
      UIPerformanceTracker.markAction();
      error.value = e.toString();
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
        _completeTest();
        return;
      }

      executeProcessingCycle(cycle);
      cycle++;
    });
  }

  void executeProcessingCycle(int cycleNumber) {
    UIPerformanceTracker.markAction();

    if (movies.isEmpty) return;

    final filterCriteria = ['genre', 'year', 'rating'][cycleNumber % 3];
    final filteredMovies =
        _performIntensiveFiltering(movies, filterCriteria, cycleNumber);

    final metrics = _calculateComplexMetrics(filteredMovies);

    final sortedMovies =
        _performComplexSorting([...filteredMovies], cycleNumber);

    final groupingCriteria =
        ['decade', 'genre', 'rating_range'][cycleNumber % 3];
    final groupedMovies =
        _performComplexGrouping(sortedMovies, groupingCriteria);

    cpuProcessingState.value = cpuProcessingState.value.copyWith(
      rawMovies: movies,
      filteredMovies: filteredMovies,
      sortedMovies: sortedMovies,
      groupedMovies: groupedMovies,
      calculatedMetrics: metrics,
      currentGenre: _getFilterValue(filterCriteria, cycleNumber),
      currentSortType: _getSortType(cycleNumber),
      currentGroupType: groupingCriteria,
      processingStep: 5,
      cycleCount: cycleNumber,
      timestamp: DateTime.now(),
    );
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
        _completeTest();
        return;
      }

      for (int i = 0; i < deepCopyOperations; i++) {
        applyFilterConfiguration(
            _filterTypes[cycle % _filterTypes.length], cycle);
        _applySortConfiguration(_sortTypes[cycle % _sortTypes.length]);
        _applyGroupConfiguration(_groupTypes[cycle % _groupTypes.length]);
        _applyPaginationConfiguration(cycle % 10);
      }

      _createComplexObjects(complexObjectsPerCycle);
      _allocateLargeLists(largeListAllocations);
      _performStringOperations(stringConcatenations);
      _createLargeMaps(mapCreations);

      if (cycle % 5 == 4) {
        _cleanupOldStates(stateRetentionPercent);
      }

      if (cycle % 8 == 7) {
        undoToStep(math.max(0, currentHistoryIndex.value - 4));
      }

      cycle++;
    });
  }

  // S03
  // Zastąp metodę _runUiGranularUpdates w BenchmarkController (GetX)

  // S03 - Enhanced UI Rendering Hell
  Future<void> _runUiGranularUpdates() async {
    // Agresywne parametry dla maksymalnego obciążenia UI
    const timerInterval = Duration(milliseconds: 8); // 125 FPS attempt
    const uiUpdatePercent = 0.60; // 60% filmów każdy cykl
    const animationPercent = 0.40; // 40% filmów animowanych
    const conditionalUpdatePercent = 0.50; // 50% conditional widgets
    const batchUpdateFrequency = 3; // Batch co 3 cykle
    const cascadeUpdateFrequency = 7; // Cascade co 7 cykli
    const memoryPressureFrequency = 11; // Memory pressure co 11 cykli

    // Inicjalizacja rozszerzonych UI states
    final initialStates = <int, UIElementState>{};
    for (final movie in movies) {
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

    UIPerformanceTracker.markAction();
    uiElementStates.value = initialStates;

    const testDurationMs = 30000; // 30 sekund intensywnego testu
    final testStartTime = DateTime.now();
    int cycleCount = 0;

    _scenarioTimer = Timer.periodic(timerInterval, (timer) {
      if (DateTime.now().difference(testStartTime).inMilliseconds >=
          testDurationMs) {
        timer.cancel();
        _completeTest();
        return;
      }

      UIPerformanceTracker.markAction();

      // CORE UPDATES - każdy cykl
      _performMassiveUIUpdates(uiUpdatePercent);
      _performAnimationUpdates(animationPercent);
      _performConditionalUpdates(conditionalUpdatePercent);

      // INTENSIVE OPERATIONS - okresowo
      if (cycleCount % batchUpdateFrequency == 0) {
        _performBatchUpdate();
      }

      if (cycleCount % cascadeUpdateFrequency == 0) {
        _performCascadingUpdates();
      }

      if (cycleCount % memoryPressureFrequency == 0) {
        _performMemoryPressureUpdate();
      }

      frameCounter.value = frameCounter.value + 1;
      cycleCount++;
    });
  }

  // Masywne aktualizacje UI - 60% filmów każdy cykl
  void _performMassiveUIUpdates(double percent) {
    final movieIds = _getRandomMovieIds(movies.length, percent);

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

    // Każda aktualizacja to osobny state change
    _updateMovieLikes(likeUpdates);
    _updateMovieProgress(progressUpdates);
    _updateMovieRatings(ratingUpdates);
    _updateMovieDownloads(downloadUpdates);
    _updateMovieViews(viewUpdates);
  }

  // Animacje - ciągłe zmiany opacity, progress, colors
  void _performAnimationUpdates(double percent) {
    final animatedMovieIds = _getRandomMovieIds(movies.length, percent);
    final newStates = Map<int, UIElementState>.from(uiElementStates);

    for (final movieId in animatedMovieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        // Ciągłe animacje
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

    uiElementStates.value = newStates;
  }

  // Conditional rendering updates
  void _performConditionalUpdates(double percent) {
    final movieIds = _getRandomMovieIds(movies.length, percent);
    final newStates = Map<int, UIElementState>.from(uiElementStates);

    for (final movieId in movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        // Zmiany powodujące dodawanie/usuwanie conditional widgets
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

    uiElementStates.value = newStates;
  }

  // Batch update - masywna operacja na wszystkich filmach
  void _performBatchUpdate() {
    UIPerformanceTracker.markAction();

    final newStates = <int, UIElementState>{};

    // Update wszystkich filmów jednocześnie
    for (final movie in movies) {
      final currentState = uiElementStates[movie.id];
      if (currentState != null) {
        newStates[movie.id] = currentState.copyWith(
          viewCount: currentState.viewCount + _random.nextInt(5),
          popularityScore: _random.nextInt(100),
          tags: List.generate(25, (i) => 'batch_tag_${movie.id}_$i'),
          metadata: {
            ...currentState.metadata,
            'batchUpdate': DateTime.now().millisecondsSinceEpoch,
            'cycle': frameCounter.value,
          },
          lastUpdated: DateTime.now(),
        );
      }
    }

    uiElementStates.value = {...uiElementStates.value, ...newStates};
  }

  // Cascading updates - update jednego wpływa na inne
  void _performCascadingUpdates() {
    UIPerformanceTracker.markAction();

    if (movies.isNotEmpty) {
      final primaryMovieId = movies[0].id;
      final primaryState = uiElementStates[primaryMovieId];

      if (primaryState != null) {
        // Update primary movie
        final newPrimaryState = primaryState.copyWith(
          isLiked: !primaryState.isLiked,
          isFeatured: true,
          popularityScore: 100,
        );

        uiElementStates[primaryMovieId] = newPrimaryState;

        // Cascade effect na related movies (first 200)
        final relatedMovies = movies.skip(1).take(200);
        final newStates = Map<int, UIElementState>.from(uiElementStates);

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

        uiElementStates.value = newStates;

        // Second cascade wave po 16ms
        Timer(const Duration(milliseconds: 16), () {
          final secondWaveMovies = movies.skip(201).take(300);
          final secondWaveStates =
              Map<int, UIElementState>.from(uiElementStates);

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

          uiElementStates.value = secondWaveStates;
        });
      }
    }
  }

  void _performMemoryPressureUpdate() {
    UIPerformanceTracker.markAction();

    final heavyStates = <int, UIElementState>{};
    final targetMovies = movies.take(500);

    for (final movie in targetMovies) {
      final currentState = uiElementStates[movie.id];
      if (currentState != null) {
        heavyStates[movie.id] = currentState.copyWith(
          tags: List.generate(100, (i) => 'heavy_tag_${movie.id}_$i'),
          thumbnails: List.generate(50, (i) => 'heavy_thumb_${movie.id}_$i'),
          metadata: {
            'heavyData': List.generate(200, (i) => 'heavy_data_${movie.id}_$i'),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'cycle': frameCounter.value,
            'randomData': List.generate(100, (i) => _random.nextDouble()),
          },
          isLiked: !currentState.isLiked,
          progress: _random.nextDouble(),
          rating: _random.nextDouble() * 10,
          lastUpdated: DateTime.now(),
        );
      }
    }

    // Batch assignment - może powodować memory spike + UI freeze
    uiElementStates.value = {...uiElementStates.value, ...heavyStates};
  }

  // Helper methods dla poszczególnych typów aktualizacji
  void _updateMovieLikes(List<int> movieIds) {
    for (final movieId in movieIds) {
      final currentState = uiElementStates[movieId];
      if (currentState != null) {
        uiElementStates[movieId] = currentState.copyWith(
          isLiked: !currentState.isLiked,
          popularityScore:
              currentState.popularityScore + (currentState.isLiked ? -1 : 1),
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }
  }

  void _updateMovieProgress(List<int> movieIds) {
    for (final movieId in movieIds) {
      final currentState = uiElementStates[movieId];
      if (currentState != null) {
        final newProgress = (currentState.progress + 0.05).clamp(0.0, 1.0);
        uiElementStates[movieId] = currentState.copyWith(
          progress: newProgress,
          isWatched: newProgress >= 1.0,
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }
  }

  void _updateMovieRatings(List<int> movieIds) {
    for (final movieId in movieIds) {
      final currentState = uiElementStates[movieId];
      if (currentState != null) {
        final newRating = (currentState.rating + 0.5).clamp(0.0, 10.0);
        uiElementStates[movieId] = currentState.copyWith(
          rating: newRating,
          isFeatured: newRating >= 8.0,
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }
  }

  void _updateMovieDownloads(List<int> movieIds) {
    for (final movieId in movieIds) {
      final currentState = uiElementStates[movieId];
      if (currentState != null) {
        uiElementStates[movieId] = currentState.copyWith(
          isDownloading: !currentState.isDownloading,
          opacity: currentState.isDownloading ? 1.0 : 0.8,
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }
  }

  void _updateMovieViews(List<int> movieIds) {
    for (final movieId in movieIds) {
      final currentState = uiElementStates[movieId];
      if (currentState != null) {
        final newViewCount = currentState.viewCount + 1;
        uiElementStates[movieId] = currentState.copyWith(
          viewCount: newViewCount,
          popularityScore: (currentState.popularityScore + (newViewCount ~/ 10))
              .clamp(0, 100),
          lastUpdated: DateTime.now(),
        );
        UIPerformanceTracker.markAction();
      }
    }
  }

  void _completeTest() {
    endTime = DateTime.now();
    UIPerformanceTracker.markAction();
    status.value = BenchmarkStatus.completed;
    _completeTestWithReports();
  }

  void _completeTestWithReports() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    UIPerformanceTracker.stopTracking();

    final memoryReport = MemoryMonitor.generateReport();
    final uiReport = UIPerformanceTracker.generateReport();

    print('=== GetX Memory Report for ${scenarioType.value} ===');
    print(memoryReport.toFormattedString());
    print('=== GetX UI Performance Report for ${scenarioType.value} ===');
    print(uiReport.toFormattedString());
  }

  void _createComplexObjects(int count) {
    UIPerformanceTracker.markAction();

    final complexData = <String, dynamic>{};
    for (int i = 0; i < count; i++) {
      final movieCopy = movies.isNotEmpty ? movies[i % movies.length] : null;

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

    final currentState = processingState.value;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['complexObjects'] = count.toDouble();
    newMetrics['memoryPressure'] = (newMetrics['memoryPressure'] ?? 0) + 1;

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Created $count complex objects'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void _allocateLargeLists(int count) {
    UIPerformanceTracker.markAction();

    final largeLists = <List<dynamic>>[];
    for (int i = 0; i < count; i++) {
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

    final currentState = processingState.value;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['largeListsAllocated'] = count.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Allocated $count large lists'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void _performStringOperations(int count) {
    UIPerformanceTracker.markAction();

    String result = '';
    for (int i = 0; i < count; i++) {
      result += 'String operation $i with movie data: ';
      if (movies.isNotEmpty) {
        final movie = movies[i % movies.length];
        result +=
            '${movie.title} - ${movie.overview.substring(0, math.min(50, movie.overview.length))}';
      }
      result += '\n';
    }

    final currentState = processingState.value;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['stringOperations'] = count.toDouble();
    newMetrics['stringLength'] = result.length.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Performed $count string operations'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void _createLargeMaps(int count) {
    UIPerformanceTracker.markAction();

    final largeMaps = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
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

    final currentState = processingState.value;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['largeMapsCreated'] = count.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Created $count large maps'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void _cleanupOldStates(double retentionPercent) {
    UIPerformanceTracker.markAction();

    final currentHistory = stateHistory.value;
    final retainCount = (currentHistory.length * retentionPercent).round();
    final newHistory = currentHistory.length > retainCount
        ? currentHistory.sublist(currentHistory.length - retainCount)
        : currentHistory;

    final newLog = [
      ...operationLog,
      'Cleaned up ${currentHistory.length - newHistory.length} old states'
    ];

    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value =
        math.min(currentHistoryIndex.value, newHistory.length - 1);
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
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

  void applyFilterConfiguration(String filterType, dynamic filterValue) {
    UIPerformanceTracker.markAction();

    final currentState = processingState.value;
    final newState = ProcessingState(
      rawMovies: movies,
      filteredMovies: _applyFilter(movies, filterType, filterValue),
      sortedMovies: currentState.sortedMovies,
      groupedMovies: currentState.groupedMovies,
      calculatedMetrics: currentState.calculatedMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Filter: $filterType'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void _applySortConfiguration(String sortType) {
    UIPerformanceTracker.markAction();

    final currentState = processingState.value;
    final sorted = [...currentState.filteredMovies];
    _applySorting(sorted, sortType);

    final newState = currentState.copyWith(
      sortedMovies: sorted,
      currentSortType: sortType,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Sort: $sortType'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void _applyGroupConfiguration(String groupType) {
    UIPerformanceTracker.markAction();

    final currentState = processingState.value;
    final grouped = _applyGrouping(currentState.sortedMovies, groupType);

    final newState = currentState.copyWith(
      groupedMovies: grouped,
      currentGroupType: groupType,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Group: $groupType'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void _applyPaginationConfiguration(int page) {
    UIPerformanceTracker.markAction();

    final currentState = processingState.value;
    final newMetrics = Map<String, double>.from(currentState.calculatedMetrics);
    newMetrics['currentPage'] = page.toDouble();

    final newState = currentState.copyWith(
      calculatedMetrics: newMetrics,
      processingStep: currentState.processingStep + 1,
      timestamp: DateTime.now(),
    );

    final newHistory = [...stateHistory, newState];
    final newLog = [...operationLog, 'Paginate: $page'];

    processingState.value = newState;
    UIPerformanceTracker.markAction();
    stateHistory.value = newHistory;
    UIPerformanceTracker.markAction();
    currentHistoryIndex.value = newHistory.length - 1;
    UIPerformanceTracker.markAction();
    operationLog.value = newLog;
  }

  void undoToStep(int stepNumber) {
    UIPerformanceTracker.markAction();

    if (stepNumber >= 0 && stepNumber < stateHistory.length) {
      final restoredState = stateHistory[stepNumber];
      final newLog = [...operationLog, 'Undo to step: $stepNumber'];

      processingState.value = restoredState;
      UIPerformanceTracker.markAction();
      currentHistoryIndex.value = stepNumber;
      UIPerformanceTracker.markAction();
      operationLog.value = newLog;
    }
  }

  void updateMovieLikeStatus(List<int> movieIds) {
    const mathIterations = 15;
    final newStates = Map<int, UIElementState>.from(uiElementStates);

    for (final movieId in movieIds) {
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

    uiElementStates.value = newStates;
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieViewCount(List<int> movieIds) {
    final newStates = Map<int, UIElementState>.from(uiElementStates);

    for (final movieId in movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          viewCount: currentState.viewCount + 1,
          lastUpdated: DateTime.now(),
        );
      }
    }

    uiElementStates.value = newStates;
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieProgress(List<int> movieIds) {
    final newStates = Map<int, UIElementState>.from(uiElementStates);

    for (final movieId in movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        final newProgress = (currentState.progress + 0.05).clamp(0.0, 1.0);
        newStates[movieId] = currentState.copyWith(
          progress: newProgress,
          lastUpdated: DateTime.now(),
        );
      }
    }

    uiElementStates.value = newStates;
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieDownloadStatus(List<int> movieIds) {
    final newStates = Map<int, UIElementState>.from(uiElementStates);

    for (final movieId in movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          isDownloading: !currentState.isDownloading,
          lastUpdated: DateTime.now(),
        );
      }
    }

    uiElementStates.value = newStates;
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieRating(List<int> movieIds) {
    final newStates = Map<int, UIElementState>.from(uiElementStates);

    for (final movieId in movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        final newRating = (currentState.rating + 0.5).clamp(0.0, 10.0);
        newStates[movieId] = currentState.copyWith(
          rating: newRating,
          lastUpdated: DateTime.now(),
        );
      }
    }

    uiElementStates.value = newStates;
    lastUpdatedMovieIds.value = movieIds;
  }

  void heavySortOperation(int iterations) {
    UIPerformanceTracker.markAction();

    final sorted = [...movies];
    sorted.sort((a, b) {
      double aWeight = a.voteAverage;
      double bWeight = b.voteAverage;

      for (int k = 0; k < iterations; k++) {
        aWeight += math.sin(a.id * k / 50.0) * 0.001;
        bWeight += math.sin(b.id * k / 50.0) * 0.001;
      }

      return bWeight.compareTo(aWeight);
    });

    movies.value = sorted;
    frameCounter.value = frameCounter.value + 1;
  }

  void heavyFilterOperation(int iterations) {
    UIPerformanceTracker.markAction();

    final filtered = <Movie>[];
    for (final movie in movies) {
      double complexity = 0;
      for (int i = 0; i < iterations * 5; i++) {
        complexity += math.cos(movie.id * i / 100.0);
      }

      if (complexity > -iterations * 2) {
        filtered.add(movie);
      }
    }

    final newProcessingState = processingState.value.copyWith(
      filteredMovies: filtered,
      processingStep: processingState.value.processingStep + 1,
      timestamp: DateTime.now(),
    );

    processingState.value = newProcessingState;
    frameCounter.value = frameCounter.value + 1;
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
      final randomIndex = _random.nextInt(movies.length);
      movieIds.add(movies[randomIndex].id);
    }

    return movieIds;
  }
}
