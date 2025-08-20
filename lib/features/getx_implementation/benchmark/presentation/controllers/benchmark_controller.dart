import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/models/enriched_movie.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'package:moviedb_benchmark/features/getx_implementation/theme/controllers/theme_controller.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/benchmark/bloc/benchmark_state.dart';

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

  @override
  void onClose() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    super.onClose();
  }

  void startBenchmark(ScenarioType scenario, int size) async {
    UIPerformanceTracker.markStateUpdate(); // DODANE
    scenarioType.value = scenario;
    dataSize = size;
    startTime = DateTime.now();
    status.value = BenchmarkStatus.loading;

    MemoryMonitor.stopMonitoring();
    MemoryMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
    UIPerformanceTracker.startTracking(); // ZMIANA

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
      UIPerformanceTracker.markStateUpdate(); // DODANE
      status.value = BenchmarkStatus.error;
      error.value = e.toString();
      _completeTestWithReports();
    }
  }

  // S01 - API Data Streaming
  Future<void> _runApiStreamingScenario(int dataSize) async {
    UIPerformanceTracker.markStateUpdate(); // DODANE
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
      UIPerformanceTracker.markStateUpdate(); // DODANE

      final newMovies = await apiClient.getPopularMovies(page: _currentPage);
      final allMovies = [...movies, ...newMovies];

      // Każda aktualizacja reactive variable = state update
      movies.value = allMovies;
      UIPerformanceTracker.markStateUpdate(); // DODANE
      filteredMovies.value = allMovies;
      UIPerformanceTracker.markStateUpdate(); // DODANE
      loadedCount.value = allMovies.length;
      UIPerformanceTracker.markStateUpdate(); // DODANE
      progressCounter.value = _currentPage;
      UIPerformanceTracker.markStateUpdate(); // DODANE
      statusText.value = 'Loading page $_currentPage...';
    } catch (e) {
      // Handle error but continue
    }
  }

  // S02 - Real-time Data Filtering
  Future<void> _runRealtimeFilteringScenario(int dataSize) async {
    // Load initial data
    final loadedMovies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIPerformanceTracker.markStateUpdate(); // DODANE
    movies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    filteredMovies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    loadedCount.value = loadedMovies.length;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    currentFilterIndex.value = 0;
    UIPerformanceTracker.markStateUpdate(); // DODANE
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

    UIPerformanceTracker.markStateUpdate(); // DODANE

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
    UIPerformanceTracker.markStateUpdate(); // DODANE
    currentFilterIndex.value = currentFilterIndex.value + 1;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    statusText.value =
        'Filter ${currentFilterIndex.value}: ${filtered.length} movies';
  }

  // S03 - Memory Pressure Simulation
  Future<void> _runMemoryPressureScenario(int dataSize) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIPerformanceTracker.markStateUpdate(); // DODANE
    movies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    filteredMovies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    loadedCount.value = loadedMovies.length;
    UIPerformanceTracker.markStateUpdate(); // DODANE
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
    UIPerformanceTracker.markStateUpdate(); // DODANE

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
    UIPerformanceTracker.markStateUpdate(); // DODANE
    statusText.value = 'Enriched: ${enriched.length} movies with extra data';
  }

  void _simplifyMoviesData() {
    UIPerformanceTracker.markStateUpdate(); // DODANE
    enrichedMovies.clear();
    UIPerformanceTracker.markStateUpdate(); // DODANE
    statusText.value = 'Simplified: Removed extra data';
  }

  // S04 - Cascading State Updates
  Future<void> _runCascadingUpdatesScenario(int dataSize) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: dataSize);

    UIPerformanceTracker.markStateUpdate(); // DODANE
    movies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    filteredMovies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    loadedCount.value = loadedMovies.length;
    UIPerformanceTracker.markStateUpdate(); // DODANE
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
    UIPerformanceTracker.markStateUpdate(); // DODANE
    isAccessibilityMode.value = !isAccessibilityMode.value;
    Get.find<ThemeController>().setAccessibilityMode(isAccessibilityMode.value);

    // 2. View mode change
    UIPerformanceTracker.markStateUpdate(); // DODANE
    viewMode.value =
        viewMode.value == ViewMode.list ? ViewMode.grid : ViewMode.list;

    // 3. Toggle favorites on random movies
    final randomMovies =
        List.generate(10, (i) => movies[_random.nextInt(movies.length)].id)
            .toSet();
    UIPerformanceTracker.markStateUpdate(); // DODANE
    expandedMovies.value = randomMovies;

    // 4. Update filter
    UIPerformanceTracker.markStateUpdate(); // DODANE
    final randomGenre = [28, 35, 18, 27, 16][_random.nextInt(5)];
    final filtered =
        movies.where((m) => m.genreIds.contains(randomGenre)).toList();

    filteredMovies.value = filtered;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    statusText.value =
        'Cascade ${progressCounter.value + 1}: ${filtered.length} movies';
    UIPerformanceTracker.markStateUpdate(); // DODANE
    progressCounter.value = progressCounter.value + 1;
  }

  // S05 - High-Frequency Updates
  Future<void> _runHighFrequencyScenario(int dataSize) async {
    final loadedMovies =
        await apiClient.loadAllMovies(totalItems: math.min(dataSize, 1000));

    UIPerformanceTracker.markStateUpdate(); // DODANE
    movies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    filteredMovies.value = loadedMovies;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    loadedCount.value = loadedMovies.length;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    multiCounters.value = List.filled(20, 0);
    UIPerformanceTracker.markStateUpdate(); // DODANE
    loadingStates.value = List.filled(20, false);
    UIPerformanceTracker.markStateUpdate(); // DODANE
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
    UIPerformanceTracker.markStateUpdate(); // DODANE

    // Update multiple reactive variables
    final newCounters = multiCounters.map((c) => c + 1).toList();
    final newLoadingStates =
        loadingStates.map((s) => _random.nextBool()).toList();

    progressCounter.value = progressCounter.value + 1;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    statusText.value = 'Frame ${progressCounter.value}';
    UIPerformanceTracker.markStateUpdate(); // DODANE
    multiCounters.value = newCounters;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    loadingStates.value = newLoadingStates;
  }

  void completeTest() {
    endTime = DateTime.now();
    UIPerformanceTracker.markStateUpdate(); // DODANE
    status.value = BenchmarkStatus.completed;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    isAutoScrolling.value = false;
    UIPerformanceTracker.markStateUpdate(); // DODANE
    isStreamingActive.value = false;
    _completeTestWithReports();
  }

  void _completeTestWithReports() {
    _scenarioTimer?.cancel();
    MemoryMonitor.stopMonitoring();
    UIPerformanceTracker.stopTracking(); // ZMIANA

    final memoryReport = MemoryMonitor.generateReport();
    final upmReport = UIPerformanceTracker.generateReport(); // ZMIANA

    print('=== GetX Memory Report for ${scenarioType.value} ===');
    print(memoryReport.toFormattedString());
    print('=== GetX UMP Report for ${scenarioType.value} ==='); // ZMIANA
    print(upmReport.toFormattedString());
  }

  // Zachowane stare metody z dodanym state update tracking
  Future<void> loadMoreMovies() async {
    if (isLoadingMore || loadedCount.value >= dataSize) return;

    isLoadingMore = true;
    _currentPage++;

    try {
      final newMovies = await apiClient.getPopularMovies(page: _currentPage);
      final moviesToAdd = newMovies.take(dataSize - loadedCount.value).toList();

      final allMovies = [...movies, ...moviesToAdd];

      UIPerformanceTracker.markStateUpdate(); // DODANE
      movies.value = allMovies;
      UIPerformanceTracker.markStateUpdate(); // DODANE
      filteredMovies.value = allMovies;
      UIPerformanceTracker.markStateUpdate(); // DODANE
      loadedCount.value = allMovies.length;

      if (allMovies.length >= dataSize) {
        UIPerformanceTracker.markStateUpdate(); // DODANE
        isAutoScrolling.value = false;
        completeTest();
      }
    } catch (e) {
      UIPerformanceTracker.markStateUpdate(); // DODANE
      error.value = e.toString();
      UIPerformanceTracker.markStateUpdate(); // DODANE
      status.value = BenchmarkStatus.error;
      _completeTestWithReports();
    } finally {
      isLoadingMore = false;
    }
  }

  void filterMovies(List<int> genreIds) {
    UIPerformanceTracker.markStateUpdate(); // DODANE
    filteredMovies.value = movies
        .where((movie) => movie.genreIds.any((id) => genreIds.contains(id)))
        .toList();
  }

  void sortMovies({required bool byReleaseDate}) {
    UIPerformanceTracker.markStateUpdate(); // DODANE
    final sorted = [...filteredMovies];
    if (byReleaseDate) {
      sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else {
      sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }
    filteredMovies.value = sorted;
  }

  void toggleViewMode() {
    UIPerformanceTracker.markStateUpdate(); // DODANE
    viewMode.value =
        viewMode.value == ViewMode.list ? ViewMode.grid : ViewMode.list;
  }

  void toggleAccessibilityMode() {
    UIPerformanceTracker.markStateUpdate(); // DODANE
    isAccessibilityMode.value = !isAccessibilityMode.value;
    Get.find<ThemeController>().setAccessibilityMode(isAccessibilityMode.value);
  }

  void toggleMovieExpanded(int movieId) {
    UIPerformanceTracker.markStateUpdate(); // DODANE
    if (expandedMovies.contains(movieId)) {
      expandedMovies.remove(movieId);
    } else {
      expandedMovies.add(movieId);
    }
  }
}
