import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

abstract class BenchmarkEvent extends Equatable {
  const BenchmarkEvent();

  @override
  List<Object?> get props => [];
}

class StartBenchmark extends BenchmarkEvent {
  final ScenarioType scenarioType;
  final int dataSize;

  const StartBenchmark({
    required this.scenarioType,
    required this.dataSize,
  });

  @override
  List<Object?> get props => [scenarioType, dataSize];
}

// S01 - CPU Processing Pipeline Events
class ProcessMoviesByGenre extends BenchmarkEvent {
  final String genre;
  const ProcessMoviesByGenre(this.genre);
  @override
  List<Object?> get props => [genre];
}

class CalculateAverageRating extends BenchmarkEvent {}

class SortMoviesByMetric extends BenchmarkEvent {}

class GroupMoviesByDecade extends BenchmarkEvent {}

class UpdateFinalProcessingState extends BenchmarkEvent {}

// S02 - Memory State History Events
class ApplyFilterConfiguration extends BenchmarkEvent {
  final String filterType;
  final dynamic filterValue;

  const ApplyFilterConfiguration(this.filterType, this.filterValue);
  @override
  List<Object?> get props => [filterType, filterValue];
}

class ApplySortConfiguration extends BenchmarkEvent {
  final String sortType;
  const ApplySortConfiguration(this.sortType);
  @override
  List<Object?> get props => [sortType];
}

class ApplyGroupConfiguration extends BenchmarkEvent {
  final String groupType;
  const ApplyGroupConfiguration(this.groupType);
  @override
  List<Object?> get props => [groupType];
}

class ApplyPaginationConfiguration extends BenchmarkEvent {
  final int page;
  const ApplyPaginationConfiguration(this.page);
  @override
  List<Object?> get props => [page];
}

class UndoLastOperation extends BenchmarkEvent {}

class UndoToStep extends BenchmarkEvent {
  final int stepNumber;
  const UndoToStep(this.stepNumber);
  @override
  List<Object?> get props => [stepNumber];
}

// S03 - UI Updates Events
class UpdateMovieLikeStatus extends BenchmarkEvent {
  final List<int> movieIds;
  const UpdateMovieLikeStatus(this.movieIds);
  @override
  List<Object?> get props => [movieIds];
}

class UpdateMovieViewCount extends BenchmarkEvent {
  final List<int> movieIds;
  const UpdateMovieViewCount(this.movieIds);
  @override
  List<Object?> get props => [movieIds];
}

class UpdateMovieProgress extends BenchmarkEvent {
  final List<int> movieIds;
  const UpdateMovieProgress(this.movieIds);
  @override
  List<Object?> get props => [movieIds];
}

class UpdateMovieDownloadStatus extends BenchmarkEvent {
  final List<int> movieIds;
  const UpdateMovieDownloadStatus(this.movieIds);
  @override
  List<Object?> get props => [movieIds];
}

class UpdateMovieRating extends BenchmarkEvent {
  final List<int> movieIds;
  const UpdateMovieRating(this.movieIds);
  @override
  List<Object?> get props => [movieIds];
}

class BenchmarkCompleted extends BenchmarkEvent {}
