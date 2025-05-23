import 'package:get/get.dart';
import 'dart:async';
import '../../../../core/models/movie.dart';
import '../../../../core/api/tmdb_api_client.dart';
import '../../../../utils/performance_logger.dart';
import '../../../getx_implementation/theme/controllers/theme_controller.dart';

enum BenchmarkStatus {
  initial,
  loading,
  loaded,
  running,
  completed,
  error,
}

enum ViewMode { list, grid }

class BenchmarkController extends GetxController {
  final TmdbApiClient apiClient = Get.find();
  
  final status = BenchmarkStatus.initial.obs;
  final movies = <Movie>[].obs;
  final filteredMovies = <Movie>[].obs;
  final viewMode = ViewMode.list.obs;
  final isAccessibilityMode = false.obs;
  final expandedMovies = <int>{}.obs;
  final error = Rx<String?>(null);
  final loadedCount = 0.obs;
  final isAutoScrolling = false.obs;
  
  String scenarioId = '';
  int dataSize = 0;
  DateTime? startTime;
  DateTime? endTime;
  Timer? _autoScrollTimer;
  int _currentPage = 1;

  void startBenchmark(String scenario, int size) async {
    scenarioId = scenario;
    dataSize = size;
    startTime = DateTime.now();
    status.value = BenchmarkStatus.loading;
    
    try {
      switch (scenario) {
        case 'S01':
          await _runScenario1(size);
          break;
        case 'S02':
          await _runScenario2(size);
          break;
        case 'S03':
          await _runScenario3(size);
          break;
        case 'S04':
          await _runScenario4(size);
          break;
        case 'S05':
          await _runScenario5(size);
          break;
      }
    } catch (e) {
      status.value = BenchmarkStatus.error;
      error.value = e.toString();
    }
  }

  Future<void> _runScenario1(int size) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: size);
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    endTime = DateTime.now();
    status.value = BenchmarkStatus.completed;
    _showCompletionMessage();
  }

  Future<void> _runScenario2(int size) async {
    _currentPage = 1;
    final initialMovies = await apiClient.getPopularMovies(page: _currentPage);
    
    movies.value = initialMovies;
    filteredMovies.value = initialMovies;
    loadedCount.value = initialMovies.length;
    status.value = BenchmarkStatus.running;
    isAutoScrolling.value = true;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (loadedCount.value < size) {
        autoScrollTick();
      } else {
        completeTest();
      }
    });
  }

  Future<void> _runScenario3(int size) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: size);
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    status.value = BenchmarkStatus.running;

    await Future.delayed(const Duration(milliseconds: 100));
    filterMovies([28, 12]);
    
    await Future.delayed(const Duration(milliseconds: 100));
    sortMovies(byReleaseDate: true);
    
    await Future.delayed(const Duration(milliseconds: 100));
    completeTest();
  }

  Future<void> _runScenario4(int size) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: size);
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    status.value = BenchmarkStatus.running;

    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      toggleViewMode();
    }
    
    completeTest();
  }

  Future<void> _runScenario5(int size) async {
    final loadedMovies = await apiClient.loadAllMovies(totalItems: size);
    movies.value = loadedMovies;
    filteredMovies.value = loadedMovies;
    loadedCount.value = loadedMovies.length;
    status.value = BenchmarkStatus.running;

    await Future.delayed(const Duration(milliseconds: 500));
    toggleAccessibilityMode();
    
    for (int i = 0; i < 10 && i < movies.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      toggleMovieExpanded(movies[i].id);
    }
    
    completeTest();
  }

  Future<void> loadMoreMovies() async {
    if (loadedCount.value >= dataSize) return;

    _currentPage++;
    final newMovies = await apiClient.getPopularMovies(page: _currentPage);
    movies.addAll(newMovies);
    filteredMovies.addAll(newMovies);
    loadedCount.value = movies.length;
  }

  void filterMovies(List<int> genreIds) {
    filteredMovies.value = movies
        .where((movie) => movie.genreIds.any((id) => genreIds.contains(id)))
        .toList();
  }

  void sortMovies({required bool byReleaseDate}) {
    final sorted = [...filteredMovies];
    if (byReleaseDate) {
      sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else {
      sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }
    filteredMovies.value = sorted;
  }

  void toggleViewMode() {
    viewMode.value = viewMode.value == ViewMode.list 
        ? ViewMode.grid 
        : ViewMode.list;
  }

  void toggleAccessibilityMode() {
    isAccessibilityMode.value = !isAccessibilityMode.value;
    Get.find<ThemeController>().setAccessibilityMode(isAccessibilityMode.value);
  }

  void toggleMovieExpanded(int movieId) {
    if (expandedMovies.contains(movieId)) {
      expandedMovies.remove(movieId);
    } else {
      expandedMovies.add(movieId);
    }
  }

  void autoScrollTick() {
    if (loadedCount.value < dataSize) {
      loadMoreMovies();
    }
  }

  void completeTest() {
    _autoScrollTimer?.cancel();
    endTime = DateTime.now();
    status.value = BenchmarkStatus.completed;
    isAutoScrolling.value = false;
    _showCompletionMessage();
  }

  void _showCompletionMessage() {
    final duration = endTime!.difference(startTime!);
    
    PerformanceLogger.logTestResult(
      library: 'GetX',
      scenarioId: scenarioId,
      dataSize: dataSize,
      executionTime: duration,
    );
    
    Get.snackbar(
      'Test zakończony',
      'Czas: ${duration.inSeconds}.${duration.inMilliseconds % 1000} s',
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.purple,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    _autoScrollTimer?.cancel();
    super.onClose();
  }
}