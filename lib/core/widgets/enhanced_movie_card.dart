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
    return AnimatedOpacity(
      opacity: uiState.opacity,
      duration: const Duration(milliseconds: 150),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          border: uiState.isHighlighted
              ? Border.all(color: Colors.blue, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: uiState.isFeatured
              ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 8)]
              : null,
        ),
        child: Card(
          color: uiState.isWatched ? Colors.grey[100] : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Main content row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMoviePoster(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleSection(context),
                          const SizedBox(height: 8),
                          _buildInteractiveElements(),
                        ],
                      ),
                    ),
                  ],
                ),

                // Conditional elements section
                if (_hasConditionalElements()) ...[
                  const SizedBox(height: 12),
                  _buildConditionalElements(),
                ],

                // Animation section
                if (uiState.isAnimating) ...[
                  const SizedBox(height: 8),
                  _buildAnimationSection(),
                ],

                // Featured content
                if (uiState.isFeatured) ...[
                  const SizedBox(height: 8),
                  _buildFeaturedContent(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoviePoster() {
    return Stack(
      children: [
        ClipRRect(
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
        ),

        // Overlay elements based on state
        if (uiState.isDownloading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: uiState.progress,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),

        if (uiState.isWatched)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ],
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

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                movie.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: uiState.isFeatured ? FontWeight.bold : null,
                      color: uiState.isHighlighted ? Colors.blue : null,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (uiState.popularityScore > 80)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HOT',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),

        // Popularity score bar
        if (uiState.popularityScore > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: uiState.popularityScore / 100.0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    uiState.popularityScore > 70
                        ? Colors.red
                        : uiState.popularityScore > 40
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${uiState.popularityScore}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveElements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row of interactive elements
        Row(
          children: [
            _buildLikeButton(),
            const SizedBox(width: 16),
            _buildViewCounter(),
            const Spacer(),
            _buildStarRating(),
          ],
        ),

        const SizedBox(height: 8),

        // Progress bar with animation
        _buildProgressBar(),

        const SizedBox(height: 8),

        // Second row
        Row(
          children: [
            _buildDownloadButton(),
            const Spacer(),
            if (uiState.tags.isNotEmpty)
              Text(
                'Tags: ${uiState.tags.length}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: () {
        UIPerformanceTracker.markAction();
        onLikeTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: uiState.isLiked ? 8 : 6,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: uiState.isLiked ? Colors.red.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                uiState.isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(uiState.isLiked),
                color: uiState.isLiked ? Colors.red : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            const Text('Like'),
          ],
        ),
      ),
    );
  }

  Widget _buildViewCounter() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: uiState.viewCount > 100 ? Colors.blue.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${uiState.viewCount}',
              key: ValueKey(uiState.viewCount),
              style: TextStyle(
                fontSize: 12,
                color: uiState.viewCount > 100 ? Colors.blue : Colors.grey,
                fontWeight: uiState.viewCount > 100 ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress: ${(uiState.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            if (uiState.progress >= 1.0)
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: LinearProgressIndicator(
            value: uiState.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              uiState.progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: () {
        UIPerformanceTracker.markAction();
        onDownloadTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: uiState.isDownloading ? Colors.orange : Colors.green,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                uiState.isDownloading ? Icons.downloading : Icons.download,
                key: ValueKey(uiState.isDownloading),
                size: 16,
                color: Colors.white,
              ),
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
          final starValue = index + 1;
          return AnimatedContainer(
            duration: Duration(milliseconds: 100 * (index + 1)),
            child: Icon(
              starValue <= uiState.rating ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            ),
          );
        }),
        const SizedBox(width: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            uiState.rating.toStringAsFixed(1),
            key: ValueKey(uiState.rating.toStringAsFixed(1)),
            style: TextStyle(
              fontSize: 12,
              fontWeight: uiState.rating >= 8.0 ? FontWeight.bold : null,
              color: uiState.rating >= 8.0 ? Colors.amber[700] : null,
            ),
          ),
        ),
      ],
    );
  }

  bool _hasConditionalElements() {
    return uiState.isLiked && uiState.rating >= 4.0 ||
        uiState.progress > 0.5 ||
        uiState.viewCount > 100 ||
        uiState.popularityScore > 80;
  }

  Widget _buildConditionalElements() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (uiState.isLiked && uiState.rating >= 4.0)
          _buildBadge('Favorite', Colors.red, Icons.favorite),
        if (uiState.progress > 0.5)
          _buildBadge('Halfway', Colors.blue, Icons.star_half),
        if (uiState.viewCount > 100)
          _buildBadge('Popular', Colors.purple, Icons.trending_up),
        if (uiState.popularityScore > 80)
          _buildBadge('Hot', Colors.red, Icons.local_fire_department),
        if (uiState.progress == 1.0)
          _buildBadge('Completed', Colors.green, Icons.check_circle),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
            Colors.red.withOpacity(0.3),
          ],
          stops: [
            0.0,
            uiState.animationProgress,
            1.0,
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Text(
            'Featured Content',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
          const Spacer(),
          Text(
            '${uiState.metadata.length} props',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
