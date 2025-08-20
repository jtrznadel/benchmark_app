import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/benchmark/bloc/benchmark_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

abstract class BenchmarkEvent extends Equatable {
  const BenchmarkEvent();

  @override
  List<Object?> get props => [];
}

class StartBenchmark extends BenchmarkEvent {
  final ScenarioType scenarioType; // ZMIANA: String -> ScenarioType
  final int dataSize;

  const StartBenchmark({
    required this.scenarioType,
    required this.dataSize,
  });

  @override
  List<Object?> get props => [scenarioType, dataSize];
}

// NOWE eventy dla nowych scenariuszy
class StreamingTick extends BenchmarkEvent {}

class FilteringTick extends BenchmarkEvent {}

class MemoryPressureTick extends BenchmarkEvent {}

class CascadingUpdateTick extends BenchmarkEvent {}

class HighFrequencyTick extends BenchmarkEvent {}

class EnrichMoviesData extends BenchmarkEvent {}

class SimplifyMoviesData extends BenchmarkEvent {}

// Zachowane stare eventy
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

class BenchmarkCompleted extends BenchmarkEvent {}
