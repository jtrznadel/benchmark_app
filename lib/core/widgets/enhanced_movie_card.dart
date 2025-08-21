import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import '../models/movie.dart';
import '../models/ui_element_state.dart';
import '../api/api_constants.dart';

class EnhancedMovieCard extends StatelessWidget {
  final Movie movie;
  final UIElementState uiState;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDownloadTap;

  const EnhancedMovieCard({
    super.key,
    required this.movie,
    required this.uiState,
    this.onLikeTap,
    this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster (never rebuilds)
            _buildMoviePoster(),
            const SizedBox(width: 12),
            // Movie Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (never rebuilds)
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Interactive elements
                  _buildInteractiveElements(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviePoster() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: movie.posterPath != null
          ? Image.network(
              '${ApiConstants.imageBaseUrl}${movie.posterPath}',
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderPoster(),
            )
          : _buildPlaceholderPoster(),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey[300],
      child: const Icon(Icons.movie, size: 30),
    );
  }

  Widget _buildInteractiveElements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Like Button and View Count Row
        Row(
          children: [
            _buildLikeButton(),
            const SizedBox(width: 16),
            _buildViewCounter(),
          ],
        ),
        const SizedBox(height: 8),
        // Progress Bar
        _buildProgressBar(),
        const SizedBox(height: 8),
        // Download Button and Rating Row
        Row(
          children: [
            _buildDownloadButton(),
            const Spacer(),
            _buildStarRating(),
          ],
        ),
      ],
    );
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: () {
        // Oznacz akcję użytkownika dla pomiaru latencji
        UIPerformanceTracker.markAction();
        onLikeTap?.call();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            uiState.isLiked ? Icons.favorite : Icons.favorite_border,
            color: uiState.isLiked ? Colors.red : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 4),
          const Text('Like'),
        ],
      ),
    );
  }

  Widget _buildViewCounter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.visibility, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '${uiState.viewCount}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress: ${(uiState.progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: uiState.progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: () {
        // Oznacz akcję użytkownika dla pomiaru latencji
        UIPerformanceTracker.markAction();
        onDownloadTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: uiState.isDownloading ? Colors.orange : Colors.green,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              uiState.isDownloading ? Icons.downloading : Icons.download,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              uiState.isDownloading ? 'Downloading' : 'Download',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final rating = uiState.rating;
          final starValue = index + 1;
          return Icon(
            starValue <= rating ? Icons.star : Icons.star_border,
            size: 16,
            color: Colors.amber,
          );
        }),
        const SizedBox(width: 4),
        Text(
          uiState.rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
