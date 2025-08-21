import 'package:equatable/equatable.dart';

class UIElementState extends Equatable {
  final int movieId;
  final bool isLiked;
  final int viewCount;
  final double progress;
  final bool isDownloading;
  final double rating;
  final DateTime lastUpdated;

  UIElementState({
    required this.movieId,
    this.isLiked = false,
    this.viewCount = 0,
    this.progress = 0.0,
    this.isDownloading = false,
    this.rating = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime(2024, 1, 1);

  UIElementState copyWith({
    int? movieId,
    bool? isLiked,
    int? viewCount,
    double? progress,
    bool? isDownloading,
    double? rating,
    DateTime? lastUpdated,
  }) {
    return UIElementState(
      movieId: movieId ?? this.movieId,
      isLiked: isLiked ?? this.isLiked,
      viewCount: viewCount ?? this.viewCount,
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      rating: rating ?? this.rating,
      lastUpdated: lastUpdated ?? DateTime.now(),
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
      ];
}
