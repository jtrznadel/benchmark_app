import 'dart:math' as math;
import 'package:get/get.dart';
import 'dart:async';
import 'package:moviedb_benchmark/core/utils/enums.dart';

import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/enriched_movie.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/uir_tracker.dart';
import 'package:moviedb_benchmark/features/getx_implementation/theme/controllers/theme_controller.dart';

class BenchmarkController extends GetxController {
  final TmdbApiClient apiClient = Get.put(TmdbApiClient());

  final status = BenchmarkStatus.initial.obs;
  final scenarioType = ScenarioType.apiStreaming.obs;
  final movies = <Movie>[].obs;
  final filteredMovies = <Movie>[].obs;
  final enrichedMovies = <EnrichedMovie>[].obs;
  final viewMode = ViewMode.list.obs;
  final isAccessibilityMode = false.obs;
  final expandedMovies = <int>{}.obs;
  final error = Rx<String?>(null);
  final loadedCount = 0.obs;
  final isAutoScrolling = false.obs;

  // Nowe reactive variables
  final progressCounter = 0.obs;
  final statusText = ''.obs;
  final multiCounters = <int>[].obs;
  final loadingStates = <bool>[].obs;
  final currentFilterIndex = 0.obs;
  final isStreamingActive = false.obs;

  int dataSize = 0;
  DateTime? startTime;
  DateTime? endTime;
  int _currentPage = 1;
  bool isLoadingMore = false;
  Timer? _scenarioTimer;
  final math.Random _random = math.Random();

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

  @override
  void onClose() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    super.onClose();
  }

  void startBenchmark(ScenarioType scenario, int size) async {
    scenarioType.value = scenario;
    dataSize = size;
    startTime = DateTime.now();
    status.value = BenchmarkStatus.loading;

    MemoryMonitor.stopMonitoring();
    MemoryMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
    UIRTracker.startTracking();

    try {
      switch (scenario) {
        case ScenarioType.apiStreaming:
          await _runApiStreamingScenario(size);
          break;
        case ScenarioType.realtimeFiltering:
          await _runRealtimeFilteringScenario(size);
          break;
        case ScenarioType.memoryPressure:
          await _runMemoryPressureScenario(size);
          break;
        case ScenarioType.cascadingUpdates:
          await _runCascadingUpdatesScenario(size);
          break;
        case ScenarioType.highFrequency:
          await _runHighFrequencyScenario(size);
          break;
      }
    } catch (e) {
      status.value = BenchmarkStatus.error;
      error.value = e.toString();
      _completeTestWithReports();
    }
  }

  // S01 - API Data Streaming
  Future<void> _runApiStreamingScenario(int dataSize) async {
    status.value = BenchmarkStatus.running;
    isStreamingActive.value = true;

    final maxPages = (dataSize / 20).ceil();
    _currentPage = 1;

    _scenarioTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_currentPage > maxPages) {
        timer.cancel();
        completeTest();
        return;
      }

      await _streamingTick();
      _currentPage++;
    });
  }

  Future<void> _streamingTick() async {
    try {
      UIRTracker.markStateChange('movies_update');

      final newMovies = await apiClient.getPopularMovies(page: _currentPage);
      final allMovies = [...movies, ...newMovies];

      movies.value = allMovies;
      filteredMovies.value = allMovies;
      loadedCount.value = allMovies.length;
      progressCounter.value = _currentPage;
      statusText.value = 'Loading page $_currentPage...';
    } catch (e) {
      // Handle error but continue
    }
  }

  // S02 - Real-time Data Filtering
  Future<void> _runRealtimeFilteringScenario(int dataSize) async {
    // Load initial data
    final loadedMovies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIRTracker.markStateChange('movies_update');
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    currentFilterIndex.value = 0;
    status.value = BenchmarkStatus.running;

    // Start filtering cycle
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (currentFilterIndex.value >= _predefinedFilters.length * 5) {
        timer.cancel();
        completeTest();
        return;
      }

      _filteringTick();
    });
  }

  void _filteringTick() {
    final filterIndex = currentFilterIndex.value % _predefinedFilters.length;
    final filter = _predefinedFilters[filterIndex];

    UIRTracker.markStateChange('movies_update');

    var filtered = movies.where((movie) {
      bool matchesYear = filter['year'] == null ||
          movie.releaseDate.startsWith(filter['year'].toString());
      bool matchesGenre =
          filter['genre'] == null || movie.genreIds.contains(filter['genre']);
      bool matchesRating =
          filter['rating'] == null || movie.voteAverage >= filter['rating'];

      return matchesYear && matchesGenre && matchesRating;
    }).toList();

    filteredMovies.value = filtered;
    currentFilterIndex.value = currentFilterIndex.value + 1;
    statusText.value =
        'Filter ${currentFilterIndex.value}: ${filtered.length} movies';
  }

  // S03 - Memory Pressure Simulation
  Future<void> _runMemoryPressureScenario(int dataSize) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIRTracker.markStateChange('movies_update');
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    status.value = BenchmarkStatus.running;

    int cycleCount = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      cycleCount++;

      if (cycleCount > 133) {
        // ~20 seconds
        timer.cancel();
        completeTest();
        return;
      }

      if (cycleCount % 20 == 0) {
        _simplifyMoviesData();
      } else {
        _enrichMoviesData();
      }
    });
  }

  void _enrichMoviesData() {
    UIRTracker.markStateChange('movies_update');

    final enriched = movies
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

    enrichedMovies.value = enriched;
    statusText.value = 'Enriched: ${enriched.length} movies with extra data';
  }

  void _simplifyMoviesData() {
    UIRTracker.markStateChange('movies_update');
    enrichedMovies.clear();
    statusText.value = 'Simplified: Removed extra data';
  }

  // S04 - Cascading State Updates
  Future<void> _runCascadingUpdatesScenario(int dataSize) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIRTracker.markStateChange('movies_update');
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    status.value = BenchmarkStatus.running;

    int updateCycle = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      updateCycle++;

      if (updateCycle > 100) {
        // ~30 seconds
        timer.cancel();
        completeTest();
        return;
      }

      _cascadingUpdateTick();
    });
  }

  void _cascadingUpdateTick() {
    // 1. Global theme change
    UIRTracker.markStateChange('theme_update');
    isAccessibilityMode.value = !isAccessibilityMode.value;
    Get.find<ThemeController>().setAccessibilityMode(isAccessibilityMode.value);

    // 2. View mode change
    UIRTracker.markStateChange('viewmode_update');
    viewMode.value =
        viewMode.value == ViewMode.list ? ViewMode.grid : ViewMode.list;

    // 3. Toggle favorites on random movies
    final randomMovies =
        List.generate(10, (i) => movies[_random.nextInt(movies.length)].id)
            .toSet();
    UIRTracker.markStateChange('favorites_update');
    expandedMovies.value = randomMovies;

    // 4. Update filter
    UIRTracker.markStateChange('filter_update');
    final randomGenre = [28, 35, 18, 27, 16][_random.nextInt(5)];
    final filtered =
        movies.where((m) => m.genreIds.contains(randomGenre)).toList();

    filteredMovies.value = filtered;
    statusText.value =
        'Cascade ${progressCounter.value + 1}: ${filtered.length} movies';
    progressCounter.value = progressCounter.value + 1;
  }

  // S05 - High-Frequency Updates
  Future<void> _runHighFrequencyScenario(int dataSize) async {
    final loadedMovies =
        await apiClient.loadAllMovies(totalItems: math.min(dataSize, 1000));

    UIRTracker.markStateChange('movies_update');
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    multiCounters.value = List.filled(20, 0);
    loadingStates.value = List.filled(20, false);
    status.value = BenchmarkStatus.running;

    int frameCount = 0;
    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // 60 FPS
      frameCount++;

      if (frameCount > 1200) {
        // 20 seconds at 60 FPS
        timer.cancel();
        completeTest();
        return;
      }

      _highFrequencyTick();
    });
  }

  void _highFrequencyTick() {
    UIRTracker.markStateChange('highfreq_update');

    // Update multiple reactive variables
    final newCounters = multiCounters.map((c) => c + 1).toList();
    final newLoadingStates =
        loadingStates.map((s) => _random.nextBool()).toList();

    progressCounter.value = progressCounter.value + 1;
    statusText.value = 'Frame ${progressCounter.value}';
    multiCounters.value = newCounters;
    loadingStates.value = newLoadingStates;
  }

  void completeTest() {
    endTime = DateTime.now();
    status.value = BenchmarkStatus.completed;
    isAutoScrolling.value = false;
    isStreamingActive.value = false;
    _completeTestWithReports();
  }

  void _completeTestWithReports() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    UIRTracker.stopTracking();

    final memoryReport = MemoryMonitor.generateReport();
    final uirReport = UIRTracker.generateReport();

    print('=== GetX Memory Report for ${scenarioType.value} ===');
    print(memoryReport.toFormattedString());
    print('=== GetX UIR Report for ${scenarioType.value} ===');
    print(uirReport.toFormattedString());
  }

  // Zachowane stare metody
  Future<void> loadMoreMovies() async {
    if (isLoadingMore || loadedCount.value >= dataSize) return;

    isLoadingMore = true;
    _currentPage++;

    try {
      final newMovies = await apiClient.getPopularMovies(page: _currentPage);
      final moviesToAdd = newMovies.take(dataSize - loadedCount.value).toList();

      final allMovies = [...movies, ...moviesToAdd];

      UIRTracker.markStateChange('movies_update');
      movies.value = allMovies;
      filteredMovies.value = allMovies;
      loadedCount.value = allMovies.length;

      if (allMovies.length >= dataSize) {
        isAutoScrolling.value = false;
        completeTest();
      }
    } catch (e) {
      error.value = e.toString();
      status.value = BenchmarkStatus.error;
      _completeTestWithReports();
    } finally {
      isLoadingMore = false;
    }
  }

  void filterMovies(List<int> genreIds) {
    UIRTracker.markStateChange('movies_update');
    filteredMovies.value = movies
        .where((movie) => movie.genreIds.any((id) => genreIds.contains(id)))
        .toList();
  }

  void sortMovies({required bool byReleaseDate}) {
    UIRTracker.markStateChange('movies_update');
    final sorted = [...filteredMovies];
    if (byReleaseDate) {
      sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else {
      sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }
    filteredMovies.value = sorted;
  }

  void toggleViewMode() {
    UIRTracker.markStateChange('viewmode_update');
    viewMode.value =
        viewMode.value == ViewMode.list ? ViewMode.grid : ViewMode.list;
  }

  void toggleAccessibilityMode() {
    UIRTracker.markStateChange('accessibility_update');
    isAccessibilityMode.value = !isAccessibilityMode.value;
    Get.find<ThemeController>().setAccessibilityMode(isAccessibilityMode.value);
  }

  void toggleMovieExpanded(int movieId) {
    UIRTracker.markStateChange('expand_update');
    if (expandedMovies.contains(movieId)) {
      expandedMovies.remove(movieId);
    } else {
      expandedMovies.add(movieId);
    }
  }
}
