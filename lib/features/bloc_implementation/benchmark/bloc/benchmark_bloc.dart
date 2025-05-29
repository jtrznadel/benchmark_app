import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'benchmark_event.dart';
import 'benchmark_state.dart';

class BenchmarkBloc extends Bloc<BenchmarkEvent, BenchmarkState> {
  final TmdbApiClient apiClient;
  int _currentPage = 1;
  bool isLoadingMore = false;

  BenchmarkBloc({required this.apiClient}) : super(const BenchmarkState()) {
    on<StartBenchmark>(_onStartBenchmark);
    on<LoadMoreMovies>(_onLoadMoreMovies);
    on<FilterMovies>(_onFilterMovies);
    on<SortMovies>(_onSortMovies);
    on<ToggleViewMode>(_onToggleViewMode);
    on<ToggleAccessibilityMode>(_onToggleAccessibilityMode);
    on<ToggleMovieExpanded>(_onToggleMovieExpanded);
    on<BenchmarkCompleted>(_onBenchmarkCompleted);
  }

  Future<void> _onStartBenchmark(
      StartBenchmark event, Emitter<BenchmarkState> emit) async {
    emit(state.copyWith(
      status: BenchmarkStatus.loading,
      scenarioId: event.scenarioId,
      dataSize: event.dataSize,
      startTime: DateTime.now(),
    ));

    try {
      switch (event.scenarioId) {
        case 'S01':
          await _runScenario1(event.dataSize, emit);
          break;
        case 'S02':
          await _runScenario2(event.dataSize, emit);
          break;
        case 'S03':
          await _runScenario3(event.dataSize, emit);
          break;
        case 'S04':
          await _runScenario4(event.dataSize, emit);
          break;
        case 'S05':
          await _runScenario5(event.dataSize, emit);
          break;
      }
    } catch (e) {
      emit(state.copyWith(
        status: BenchmarkStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _runScenario1(int dataSize, Emitter<BenchmarkState> emit) async {
    final movies = await apiClient.loadAllMovies(totalItems: dataSize);
    emit(state.copyWith(
      status: BenchmarkStatus.completed,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
      endTime: DateTime.now(),
    ));
  }

  Future<void> _runScenario2(int dataSize, Emitter<BenchmarkState> emit) async {
    _currentPage = 1;
    final initialMovies = await apiClient.getPopularMovies(page: _currentPage);

    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: initialMovies,
      filteredMovies: initialMovies,
      loadedCount: initialMovies.length,
      isAutoScrolling: true,
    ));
  }

  Future<void> _runScenario3(int dataSize, Emitter<BenchmarkState> emit) async {
    final movies = await apiClient.loadAllMovies(totalItems: dataSize);
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
    ));

    await Future.delayed(const Duration(milliseconds: 100));
    add(const FilterMovies(genreIds: [28, 12]));

    await Future.delayed(const Duration(milliseconds: 100));
    add(const SortMovies(byReleaseDate: true));

    await Future.delayed(const Duration(milliseconds: 100));
    add(BenchmarkCompleted());
  }

  Future<void> _runScenario4(int dataSize, Emitter<BenchmarkState> emit) async {
    final movies = await apiClient.loadAllMovies(totalItems: dataSize);
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
    ));

    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(ToggleViewMode());
    }

    add(BenchmarkCompleted());
  }

  Future<void> _runScenario5(int dataSize, Emitter<BenchmarkState> emit) async {
    final movies = await apiClient.loadAllMovies(totalItems: dataSize);
    emit(state.copyWith(
      status: BenchmarkStatus.running,
      movies: movies,
      filteredMovies: movies,
      loadedCount: movies.length,
    ));

    await Future.delayed(const Duration(milliseconds: 500));
    add(ToggleAccessibilityMode());

    for (int i = 0; i < 10 && i < movies.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      add(ToggleMovieExpanded(movieId: movies[i].id));
    }

    add(BenchmarkCompleted());
  }

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

      emit(state.copyWith(
        movies: allMovies,
        filteredMovies: allMovies,
        loadedCount: allMovies.length,
      ));

      if (allMovies.length >= state.dataSize) {
        emit(state.copyWith(isAutoScrolling: false));
      }
    } finally {
      isLoadingMore = false;
    }
  }

  void _onFilterMovies(FilterMovies event, Emitter<BenchmarkState> emit) {
    final filtered = state.movies
        .where(
            (movie) => movie.genreIds.any((id) => event.genreIds.contains(id)))
        .toList();

    emit(state.copyWith(filteredMovies: filtered));
  }

  void _onSortMovies(SortMovies event, Emitter<BenchmarkState> emit) {
    final sorted = [...state.filteredMovies];
    if (event.byReleaseDate) {
      sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else {
      sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }

    emit(state.copyWith(filteredMovies: sorted));
  }

  void _onToggleViewMode(ToggleViewMode event, Emitter<BenchmarkState> emit) {
    emit(state.copyWith(
      viewMode: state.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
    ));
  }

  void _onToggleAccessibilityMode(
      ToggleAccessibilityMode event, Emitter<BenchmarkState> emit) {
    emit(state.copyWith(isAccessibilityMode: !state.isAccessibilityMode));
  }

  void _onToggleMovieExpanded(
      ToggleMovieExpanded event, Emitter<BenchmarkState> emit) {
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
    emit(state.copyWith(
      status: BenchmarkStatus.completed,
      endTime: DateTime.now(),
      isAutoScrolling: false,
    ));
  }
}
