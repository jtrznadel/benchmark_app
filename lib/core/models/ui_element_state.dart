import 'package:equatable/equatable.dart';

class UIElementState extends Equatable {
  final int movieId;
  final bool isLiked;
  final int viewCount;
  final double progress;
  final bool isDownloading;
  final double rating;
  final DateTime lastUpdated;

  // Nowe pola dla intensywnego testowania
  final bool isAnimating;
  final double animationProgress;
  final int popularityScore;
  final bool isFeatured;
  final bool isWatched;
  final double opacity;
  final bool isHighlighted;

  UIElementState({
    required this.movieId,
    this.isLiked = false,
    this.viewCount = 0,
    this.progress = 0.0,
    this.isDownloading = false,
    this.rating = 0.0,
    DateTime? lastUpdated,
    this.isAnimating = false,
    this.animationProgress = 0.0,
    this.popularityScore = 0,
    this.isFeatured = false,
    this.isWatched = false,
    this.opacity = 1.0,
    this.isHighlighted = false,
  }) : lastUpdated = lastUpdated ?? DateTime(2024, 1, 1);

  UIElementState copyWith({
    int? movieId,
    bool? isLiked,
    int? viewCount,
    double? progress,
    bool? isDownloading,
    double? rating,
    DateTime? lastUpdated,
    bool? isAnimating,
    double? animationProgress,
    int? popularityScore,
    bool? isFeatured,
    bool? isWatched,
    double? opacity,
    bool? isHighlighted,
  }) {
    return UIElementState(
      movieId: movieId ?? this.movieId,
      isLiked: isLiked ?? this.isLiked,
      viewCount: viewCount ?? this.viewCount,
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      rating: rating ?? this.rating,
      lastUpdated: lastUpdated ?? DateTime.now(),
      isAnimating: isAnimating ?? this.isAnimating,
      animationProgress: animationProgress ?? this.animationProgress,
      popularityScore: popularityScore ?? this.popularityScore,
      isFeatured: isFeatured ?? this.isFeatured,
      isWatched: isWatched ?? this.isWatched,
      opacity: opacity ?? this.opacity,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  @override
  List<Object?> get props => [
        movieId,
        isLiked,
        viewCount,
        progress,
        isDownloading,
        rating,
        lastUpdated,
        isAnimating,
        animationProgress,
        popularityScore,
        isFeatured,
        isWatched,
        opacity,
        isHighlighted,
      ];
}
