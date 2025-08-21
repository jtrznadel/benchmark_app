import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/models/processing_state.dart';
import 'package:moviedb_benchmark/core/models/ui_element_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';

class BenchmarkController extends GetxController {
  final TmdbApiClient apiClient = Get.put(TmdbApiClient());

  // Core state
  final status = BenchmarkStatus.initial.obs;
  final scenarioType = ScenarioType.cpuProcessingPipeline.obs;
  final movies = <Movie>[].obs;
  final error = Rx<String?>(null);
  final loadedCount = 0.obs;

  // S01 - CPU Processing specific
  final processingState = ProcessingState().obs;
  final currentProcessingCycle = 0.obs;
  final genreRotation = <String>[].obs;

  // S02 - Memory State History specific
  final stateHistory = <ProcessingState>[].obs;
  final currentHistoryIndex = 0.obs;
  final operationLog = <String>[].obs;

  // S03 - UI Updates specific
  final uiElementStates = <int, UIElementState>{}.obs;
  final frameCounter = 0.obs;
  final lastUpdatedMovieIds = <int>[].obs;

  int dataSize = 0;
  DateTime? startTime;
  DateTime? endTime;
  Timer? _scenarioTimer;
  final Random _random = Random(42); // Fixed seed for consistency

  // Predefined configurations
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
      // Load initial data
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

  // S01 - CPU Processing Pipeline Implementation
  Future<void> _runCpuProcessingPipeline() async {
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (currentProcessingCycle.value >= 600) {
        // 60 seconds
        timer.cancel();
        _completeTest();
        return;
      }

      final genreIndex = currentProcessingCycle.value % _genreNames.length;
      _processMoviesByGenre(_genreNames[genreIndex]);
    });
  }

  void _processMoviesByGenre(String genre) {
    UIPerformanceTracker.markAction();

    // Step 1: Filter by genre
    final filtered = movies
        .where(
            (movie) => movie.genreIds.any((id) => _getGenreForId(id) == genre))
        .toList();

    final newProcessingState = processingState.value.copyWith(
      filteredMovies: filtered,
      currentGenre: genre,
      processingStep: 1,
    );

    processingState.value = newProcessingState;
    UIPerformanceTracker.markAction();
    currentProcessingCycle.value = currentProcessingCycle.value + 1;

    // Step 2: Calculate average rating
    _calculateAverageRating();
  }

  void _calculateAverageRating() {
    UIPerformanceTracker.markAction();

    final filtered = processingState.value.filteredMovies;
    final averageRating = filtered.isEmpty
        ? 0.0
        : filtered.map((m) => m.voteAverage).reduce((a, b) => a + b) /
            filtered.length;

    final metrics =
        Map<String, double>.from(processingState.value.calculatedMetrics);
    metrics['averageRating'] = averageRating;

    final newProcessingState = processingState.value.copyWith(
      calculatedMetrics: metrics,
      processingStep: 2,
    );

    processingState.value = newProcessingState;

    // Step 3: Sort by metric
    _sortMoviesByMetric();
  }

  void _sortMoviesByMetric() {
    UIPerformanceTracker.markAction();

    final filtered = [...processingState.value.filteredMovies];
    final averageRating =
        processingState.value.calculatedMetrics['averageRating'] ?? 0.0;

    filtered.sort((a, b) {
      final aDiff = (a.voteAverage - averageRating).abs();
      final bDiff = (b.voteAverage - averageRating).abs();
      return aDiff.compareTo(bDiff);
    });

    final newProcessingState = processingState.value.copyWith(
      sortedMovies: filtered,
      processingStep: 3,
    );

    processingState.value = newProcessingState;

    // Step 4: Group by decade
    _groupMoviesByDecade();
  }

  void _groupMoviesByDecade() {
    UIPerformanceTracker.markAction();

    final sorted = processingState.value.sortedMovies;
    final grouped = <String, List<Movie>>{};

    for (final movie in sorted) {
      final year = int.tryParse(movie.releaseDate.split('-').first) ?? 2000;
      final decade = '${(year ~/ 10) * 10}s';

      grouped.putIfAbsent(decade, () => []);
      grouped[decade]!.add(movie);
    }

    final newProcessingState = processingState.value.copyWith(
      groupedMovies: grouped,
      processingStep: 4,
    );

    processingState.value = newProcessingState;

    // Step 5: Final update
    _updateFinalProcessingState();
  }

  void _updateFinalProcessingState() {
    UIPerformanceTracker.markAction();

    final newProcessingState = processingState.value.copyWith(
      processingStep: 5,
      timestamp: DateTime.now(),
    );

    processingState.value = newProcessingState;
  }

  // S02 - Memory State History Implementation
  Future<void> _runMemoryStateHistory() async {
    int cycle = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (cycle >= 400) {
        // ~60 seconds
        timer.cancel();
        _completeTest();
        return;
      }

      // Forward operations (4 steps)
      applyFilterConfiguration(
          _filterTypes[cycle % _filterTypes.length], cycle);
      _applySortConfiguration(_sortTypes[cycle % _sortTypes.length]);
      _applyGroupConfiguration(_groupTypes[cycle % _groupTypes.length]);
      _applyPaginationConfiguration(cycle % 10);

      // Backward operations (rollback every 8th cycle)
      if (cycle % 8 == 7) {
        undoToStep(max(0, currentHistoryIndex.value - 4));
      }

      cycle++;
    });
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

  // S03 - UI Granular Updates Implementation
  Future<void> _runUiGranularUpdates() async {
    // Initialize UI states for all movies
    final initialStates = <int, UIElementState>{};
    for (final movie in movies) {
      initialStates[movie.id] = UIElementState(movieId: movie.id);
    }

    UIPerformanceTracker.markAction();
    uiElementStates.value = initialStates;

    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // 60 FPS
      if (frameCounter.value >= 1800) {
        // 30 seconds
        timer.cancel();
        _completeTest();
        return;
      }

      // Update different percentages of movies per frame
      final movieCount = movies.length;
      final likeUpdates = _getRandomMovieIds(movieCount, 0.40); // 10%
      final viewUpdates = _getRandomMovieIds(movieCount, 0.60); // 20%
      final progressUpdates = _getRandomMovieIds(movieCount, 0.15); // 5%
      final downloadUpdates = _getRandomMovieIds(movieCount, 0.09); // 3%
      final ratingUpdates = _getRandomMovieIds(movieCount, 0.15); // 1%

      updateMovieLikeStatus(likeUpdates);
      updateMovieViewCount(viewUpdates);
      updateMovieProgress(progressUpdates);
      updateMovieDownloadStatus(downloadUpdates);
      updateMovieRating(ratingUpdates);
    });
  }

  void updateMovieLikeStatus(List<int> movieIds) {
    UIPerformanceTracker.markAction();

    final newStates = Map<int, UIElementState>.from(uiElementStates);
    for (final movieId in movieIds) {
      final currentState = newStates[movieId];
      if (currentState != null) {
        newStates[movieId] = currentState.copyWith(
          isLiked: !currentState.isLiked,
          lastUpdated: DateTime.now(),
        );
      }
    }

    uiElementStates.value = newStates;
    UIPerformanceTracker.markAction();
    frameCounter.value = frameCounter.value + 1;
    UIPerformanceTracker.markAction();
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieViewCount(List<int> movieIds) {
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();
    frameCounter.value = frameCounter.value + 1;
    UIPerformanceTracker.markAction();
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieProgress(List<int> movieIds) {
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();
    frameCounter.value = frameCounter.value + 1;
    UIPerformanceTracker.markAction();
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieDownloadStatus(List<int> movieIds) {
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();
    frameCounter.value = frameCounter.value + 1;
    UIPerformanceTracker.markAction();
    lastUpdatedMovieIds.value = movieIds;
  }

  void updateMovieRating(List<int> movieIds) {
    UIPerformanceTracker.markAction();

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
    UIPerformanceTracker.markAction();
    frameCounter.value = frameCounter.value + 1;
    UIPerformanceTracker.markAction();
    lastUpdatedMovieIds.value = movieIds;
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
    final uiReport = UIPerformanceTracker.generateReport(); // ZMIENIONE

    print('=== GetX Memory Report for ${scenarioType.value} ===');
    print(memoryReport.toFormattedString());
    print(
        '=== GetX UI Performance Report for ${scenarioType.value} ==='); // ZMIENIONE
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
      final randomIndex = _random.nextInt(movies.length);
      movieIds.add(movies[randomIndex].id);
    }

    return movieIds;
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
}
