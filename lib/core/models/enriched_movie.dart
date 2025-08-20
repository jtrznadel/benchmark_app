import 'package:equatable/equatable.dart';
import 'movie.dart';

class EnrichedMovie extends Equatable {
  final Movie baseMovie;
  final List<String> cast;
  final List<String> crew;
  final List<MovieReview> reviews;
  final double watchProgress;
  final bool isFavorite;
  final bool isInWatchlist;
  final DateTime lastUpdated;

  EnrichedMovie({
    required this.baseMovie,
    this.cast = const [],
    this.crew = const [],
    this.reviews = const [],
    this.watchProgress = 0.0,
    this.isFavorite = false,
    this.isInWatchlist = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime(2024, 1, 1);

  EnrichedMovie copyWith({
    Movie? baseMovie,
    List<String>? cast,
    List<String>? crew,
    List<MovieReview>? reviews,
    double? watchProgress,
    bool? isFavorite,
    bool? isInWatchlist,
    DateTime? lastUpdated,
  }) {
    return EnrichedMovie(
      baseMovie: baseMovie ?? this.baseMovie,
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
      reviews: reviews ?? this.reviews,
      watchProgress: watchProgress ?? this.watchProgress,
      isFavorite: isFavorite ?? this.isFavorite,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        baseMovie,
        cast,
        crew,
        reviews,
        watchProgress,
        isFavorite,
        isInWatchlist,
        lastUpdated,
      ];
}

class MovieReview extends Equatable {
  final String author;
  final String content;
  final double rating;

  const MovieReview({
    required this.author,
    required this.content,
    required this.rating,
  });

  @override
  List<Object> get props => [author, content, rating];
}
