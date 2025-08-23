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

// S01
class ExecuteProcessingCycle extends BenchmarkEvent {
  final int cycleNumber;
  const ExecuteProcessingCycle(this.cycleNumber);
  @override
  List<Object?> get props => [cycleNumber];
}

// S02
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

// S03
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

class HeavySortOperation extends BenchmarkEvent {
  final int iterations;
  const HeavySortOperation(this.iterations);
  @override
  List<Object?> get props => [iterations];
}

class HeavyFilterOperation extends BenchmarkEvent {
  final int iterations;
  const HeavyFilterOperation(this.iterations);
  @override
  List<Object?> get props => [iterations];
}

class IncrementFrameCounter extends BenchmarkEvent {}

class CreateComplexObjects extends BenchmarkEvent {
  final int count;
  const CreateComplexObjects(this.count);
  @override
  List<Object?> get props => [count];
}

class AllocateLargeLists extends BenchmarkEvent {
  final int count;
  const AllocateLargeLists(this.count);
  @override
  List<Object?> get props => [count];
}

class PerformStringOperations extends BenchmarkEvent {
  final int count;
  const PerformStringOperations(this.count);
  @override
  List<Object?> get props => [count];
}

class CreateLargeMaps extends BenchmarkEvent {
  final int count;
  const CreateLargeMaps(this.count);
  @override
  List<Object?> get props => [count];
}

class CleanupOldStates extends BenchmarkEvent {
  final double retentionPercent;
  const CleanupOldStates(this.retentionPercent);
  @override
  List<Object?> get props => [retentionPercent];
}
