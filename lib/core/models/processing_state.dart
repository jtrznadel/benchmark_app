import 'package:equatable/equatable.dart';
import 'movie.dart';

class ProcessingState extends Equatable {
  final List<Movie> rawMovies;
  final List<Movie> filteredMovies;
  final List<Movie> sortedMovies;
  final Map<String, List<Movie>> groupedMovies;
  final Map<String, double> calculatedMetrics;
  final String currentGenre;
  final String currentSortType;
  final String currentGroupType;
  final int processingStep;
  final DateTime timestamp;

  ProcessingState({
    this.rawMovies = const [],
    this.filteredMovies = const [],
    this.sortedMovies = const [],
    this.groupedMovies = const {},
    this.calculatedMetrics = const {},
    this.currentGenre = '',
    this.currentSortType = '',
    this.currentGroupType = '',
    this.processingStep = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime(2024, 1, 1);

  ProcessingState copyWith({
    List<Movie>? rawMovies,
    List<Movie>? filteredMovies,
    List<Movie>? sortedMovies,
    Map<String, List<Movie>>? groupedMovies,
    Map<String, double>? calculatedMetrics,
    String? currentGenre,
    String? currentSortType,
    String? currentGroupType,
    int? processingStep,
    DateTime? timestamp,
  }) {
    return ProcessingState(
      rawMovies: rawMovies ?? this.rawMovies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      sortedMovies: sortedMovies ?? this.sortedMovies,
      groupedMovies: groupedMovies ?? this.groupedMovies,
      calculatedMetrics: calculatedMetrics ?? this.calculatedMetrics,
      currentGenre: currentGenre ?? this.currentGenre,
      currentSortType: currentSortType ?? this.currentSortType,
      currentGroupType: currentGroupType ?? this.currentGroupType,
      processingStep: processingStep ?? this.processingStep,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        rawMovies,
        filteredMovies,
        sortedMovies,
        groupedMovies,
        calculatedMetrics,
        currentGenre,
        currentSortType,
        currentGroupType,
        processingStep,
        timestamp,
      ];
}
