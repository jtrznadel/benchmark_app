import 'package:equatable/equatable.dart';
import '../../../core/models/movie.dart';

abstract class BenchmarkEvent extends Equatable {
  const BenchmarkEvent();

  @override
  List<Object?> get props => [];
}

class StartBenchmark extends BenchmarkEvent {
  final String scenarioId;
  final int dataSize;

  const StartBenchmark({
    required this.scenarioId,
    required this.dataSize,
  });

  @override
  List<Object?> get props => [scenarioId, dataSize];
}

class LoadMoreMovies extends BenchmarkEvent {}

class FilterMovies extends BenchmarkEvent {
  final List<int> genreIds;

  const FilterMovies({required this.genreIds});

  @override
  List<Object?> get props => [genreIds];
}

class SortMovies extends BenchmarkEvent {
  final bool byReleaseDate;

  const SortMovies({required this.byReleaseDate});

  @override
  List<Object?> get props => [byReleaseDate];
}

class ToggleViewMode extends BenchmarkEvent {}

class ToggleAccessibilityMode extends BenchmarkEvent {}

class ToggleMovieExpanded extends BenchmarkEvent {
  final int movieId;

  const ToggleMovieExpanded({required this.movieId});

  @override
  List<Object?> get props => [movieId];
}

class AutoScrollTick extends BenchmarkEvent {}

class BenchmarkCompleted extends BenchmarkEvent {}